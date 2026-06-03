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
                // Log dropoff_done before ending trip (geofences are still active)
                let fences = (try? await GeofenceService.fetchGeofences(forTrip: id)) ?? []
                if let df = fences.first(where: { $0.zoneType == "dropoff" }) {
                    try? await GeofenceService.createEvent(TripGeofenceEvent(
                        id: UUID(), geofenceId: df.id, vehicleId: vehicleId,
                        driverId: currentUserId, eventType: "dropoff_done", occurredAt: Date()))
                    let managers = (try? await ProfileService.fetchProfilesByRole(role: "fleet_manager")) ?? []
                    for mgr in managers {
                        try? await NotificationService.createNotification(Fleet.Notification(
                            id: UUID(), userId: mgr.id,
                            title: "🏁 Drop-off Completed",
                            message: "Driver has completed the drop-off. Trip is now ending.",
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
