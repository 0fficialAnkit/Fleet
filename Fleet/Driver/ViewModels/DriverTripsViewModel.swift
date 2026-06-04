import SwiftUI
import UserNotifications

@MainActor
@Observable
final class DriverTripsViewModel {
    private(set) var trips: [Trip] = []
    private(set) var routes: [UUID: Route] = [:]
    private(set) var vehicles: [UUID: Vehicle] = [:]

    var isLoading = false
    var errorMessage: String?
    var currentUserId: UUID?

    var sortedTrips: [Trip] {
        trips.sorted(by: {
            let lDate = $0.createdAt ?? Date.distantPast
            let rDate = $1.createdAt ?? Date.distantPast
            if lDate != rDate { return lDate > rDate }
            return ($0.startTime ?? Date.distantPast) > ($1.startTime ?? Date.distantPast)
        })
    }

    func loadData() async {
        guard let userId = currentUserId else { return }
        isLoading = true
        errorMessage = nil
        do {
            trips = try await TripService.fetchTripsForDriver(driverId: userId)
            await loadEnrichmentData()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Batch-fetch routes and vehicles for all trips
    private func loadEnrichmentData() async {
        let routeIds = Set(trips.compactMap { $0.routeId })
        let vehicleIds = Set(trips.map { $0.vehicleId })

        await withTaskGroup(of: (UUID, Route?).self) { group in
            for routeId in routeIds where routes[routeId] == nil {
                group.addTask {
                    let route = try? await RouteService.fetchRoute(id: routeId)
                    return (routeId, route)
                }
            }
            for await (id, route) in group {
                if let route { routes[id] = route }
            }
        }

        await withTaskGroup(of: (UUID, Vehicle?).self) { group in
            for vehicleId in vehicleIds where vehicles[vehicleId] == nil {
                group.addTask {
                    let vehicle = try? await VehicleService.fetchVehicle(id: vehicleId)
                    return (vehicleId, vehicle)
                }
            }
            for await (id, vehicle) in group {
                if let vehicle { vehicles[id] = vehicle }
            }
        }
    }

    func setupRealtime() {
        RealtimeManager.shared.addTripsChangeHandler { [weak self] in
            Task { await self?.loadData() }
        }

        // Global zone-entry cache writer.
        // TripDetailView caches zone state in UserDefaults so it survives view recreation.
        // But if TripDetailView is off-screen when the geofence fires, it misses the
        // notification and the cache is never written.
        // DriverTripsViewModel lives for the entire driver session, so it writes the cache
        // here — guaranteeing it's populated before TripDetailView even appears.
        NotificationCenter.default.addObserver(
            forName: .gfZoneEntered,
            object: nil,
            queue: .main
        ) { note in
            guard let tripIdStr = note.userInfo?["tripId"]   as? String,
                  let zoneType  = note.userInfo?["zoneType"] as? String else { return }
            // Mirror the exact UserDefaults key format used in TripDetailView
            UserDefaults.standard.set(true, forKey: "fleet.zone.\(zoneType).\(tripIdStr)")
        }
    }

    func startTrip(id: UUID, vehicleId: UUID, notes: String, imageUrls: [String]) {
        Task {
            do {
                try await TripService.startTrip(id: id)
                let inspectionId = UUID()
                let inspection = VehicleInspection(id: inspectionId, vehicleId: vehicleId, driverId: currentUserId, tripId: id, inspectionType: .preTrip, notes: notes, createdAt: Date())
                try? await InspectionService.createInspection(inspection)
                for url in imageUrls {
                    let photo = InspectionPhoto(id: UUID(), inspectionId: inspectionId, imageUrl: url)
                    try? await InspectionService.createInspectionPhoto(photo)
                }
                await loadData()
                // Location tracking is handled by DriverDashboardViewModel via realtime
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func endTrip(id: UUID, vehicleId: UUID, distance: Double?, notes: String, imageUrls: [String]) {
        print("[DriverTripsViewModel] endTrip called with distance: \(String(describing: distance))")
        Task {
            do {
                // Log trip_ended (dropoff_done was already logged when driver flipped the toggle)
                let fences = (try? await GeofenceService.fetchGeofences(forTrip: id)) ?? []
                if let df = fences.first(where: { $0.zoneType == "dropoff" }) {
                    try? await GeofenceService.createEvent(TripGeofenceEvent(
                        id: UUID(), geofenceId: df.id, vehicleId: vehicleId,
                        driverId: currentUserId, eventType: "trip_ended", occurredAt: Date()))
                    let managers = (try? await ProfileService.fetchProfilesByRole(role: "fleet_manager")) ?? []
                    for mgr in managers {
                        try? await NotificationService.createNotification(Fleet.Notification(
                            id: UUID(), userId: mgr.id,
                            title: "🏁 Trip Ended",
                            message: "Driver has completed the trip. Trip is now ending.",
                            type: .info, isRead: false, createdAt: Date()))
                    }
                }
                try await TripService.endTrip(id: id, distance: distance)
                let inspectionId = UUID()
                let inspection = VehicleInspection(id: inspectionId, vehicleId: vehicleId, driverId: currentUserId, tripId: id, inspectionType: .postTrip, notes: notes, createdAt: Date())
                try? await InspectionService.createInspection(inspection)
                for url in imageUrls {
                    let photo = InspectionPhoto(id: UUID(), inspectionId: inspectionId, imageUrl: url)
                    try? await InspectionService.createInspectionPhoto(photo)
                }
                await loadData()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Called when driver flips the Drop-off toggle ON.
    /// Saves dropoff_done using the SAME proven pattern as endTrip's trip_ended:
    /// query trip_geofences directly for the dropoff fence (it has existed since
    /// trip start — zero race). The fence id from the table is always a valid FK.
    func gf_dropoffDone(tripId: UUID, vehicleId: UUID, geofenceId: UUID?) {
        Task {
            // Primary: query trip_geofences for the dropoff fence (guaranteed valid FK)
            var dropoffFenceId: UUID? = nil
            let allFences = (try? await GeofenceService.fetchAllGeofences(forTrip: tripId)) ?? []
            if let df = allFences.first(where: { $0.zoneType == "dropoff" }) {
                dropoffFenceId = df.id
            } else if let passed = geofenceId {
                // Fallback to the id cached from the zone-entry notification
                dropoffFenceId = passed
            }

            guard let gfId = dropoffFenceId else {
                print("[Geofence] ❌ gf_dropoffDone: dropoff fence not found in trip_geofences — event not saved")
                return
            }

            do {
                try await GeofenceService.createEvent(TripGeofenceEvent(
                    id: UUID(), geofenceId: gfId, vehicleId: vehicleId,
                    driverId: currentUserId, eventType: "dropoff_done", occurredAt: Date()))
                print("[Geofence] ✅ dropoff_done saved (fence: \(gfId.uuidString.prefix(6)))")
            } catch {
                print("[Geofence] ❌ dropoff_done save failed: \(error)")
            }

            let managers = (try? await ProfileService.fetchProfilesByRole(role: "fleet_manager")) ?? []
            for mgr in managers {
                try? await NotificationService.createNotification(Fleet.Notification(
                    id: UUID(), userId: mgr.id,
                    title: "🏁 Drop-off Completed",
                    message: "Driver has completed the drop-off.",
                    type: .info, isRead: false, createdAt: Date()))
            }
        }
    }

    func gf_pickupDone(tripId: UUID, vehicleId: UUID) {
        Task {
            // Resolve a valid FK for geofence_id — never use UUID() fallback
            // as it would violate the trip_geofence_events FK constraint.
            let resolvedId: UUID?
            let fences = (try? await GeofenceService.fetchGeofences(forTrip: tripId)) ?? []
            if let pf = fences.first(where: { $0.zoneType == "pickup" }) {
                resolvedId = pf.id                  // preferred: pickup fence in DB
            } else {
                // Fallback: reuse the geofenceId from the last enter event (always valid FK)
                let recent = (try? await GeofenceService.fetchEvents(forVehicle: vehicleId, limit: 10)) ?? []
                resolvedId = recent.first(where: { $0.eventType == "enter" })?.geofenceId
            }

            if let pId = resolvedId {
                try? await GeofenceService.createEvent(TripGeofenceEvent(
                    id: UUID(), geofenceId: pId, vehicleId: vehicleId,
                    driverId: currentUserId, eventType: "pickup_done", occurredAt: Date()))
                print("[Geofence] ✅ pickup_done event saved")
            }

            // Transition CLCircularRegion from pickup → dropoff
            if let df = fences.first(where: { $0.zoneType == "dropoff" }) {
                TripGeofenceMonitor.shared.transitionToDropoff(fence: df,
                    tripId: tripId, vehicleId: vehicleId, driverId: currentUserId)
            }

            let managers = (try? await ProfileService.fetchProfilesByRole(role: "fleet_manager")) ?? []
            for mgr in managers {
                try? await NotificationService.createNotification(Fleet.Notification(
                    id: UUID(), userId: mgr.id,
                    title: "✅ Pickup Completed",
                    message: "Driver completed pickup and is heading to drop-off.",
                    type: .info, isRead: false, createdAt: Date()))
            }
        }
    }

    // MARK: - Helpers

    func routeForTrip(_ trip: Trip) -> Route? {
        guard let routeId = trip.routeId else { return nil }
        return routes[routeId]
    }

    func vehicleForTrip(_ trip: Trip) -> Vehicle? {
        vehicles[trip.vehicleId]
    }
}
