import SwiftUI
import CoreLocation

@MainActor
@Observable
final class DriverTripsViewModel {
    private(set) var trips: [Trip] = []
    private(set) var routes: [UUID: Route] = [:]
    private(set) var vehicles: [UUID: Vehicle] = [:]

    var isLoading = false
    var errorMessage: String?
    var currentUserId: UUID?

    // MARK: - Live location tracking
    private var locationManager = LocationManager()
    private var trackingTask: Task<Void, Never>?

    var sortedTrips: [Trip] {
        trips.sorted(by: { ($0.startTime ?? Date.distantFuture) < ($1.startTime ?? Date.distantFuture) })
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
                startLocationTracking(vehicleId: vehicleId)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func endTrip(id: UUID, vehicleId: UUID, notes: String, imageUrls: [String]) {
        Task {
            do {
                try await TripService.endTrip(id: id)
                stopLocationTracking()
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

    // MARK: - Location tracking

    private func startLocationTracking(vehicleId: UUID) {
        stopLocationTracking()
        locationManager.requestPermission()
        print("[LocationTracking] 🚛 Started tracking for vehicle \(vehicleId)")

        trackingTask = Task { [weak self] in
            // Wait up to 20 s for first GPS fix before entering the main loop.
            var waited = 0
            while !Task.isCancelled, waited < 20 {
                if self?.locationManager.coordinate != nil { break }
                print("[LocationTracking] ⏳ Waiting for GPS fix… (\(waited)s)")
                try? await Task.sleep(for: .seconds(1))
                waited += 1
            }

            // Push immediately on trip start, then every 15 seconds.
            while !Task.isCancelled {
                if let coord = self?.locationManager.coordinate {
                    print("[LocationTracking] 📍 Pushing location — lat:\(String(format: "%.5f", coord.latitude)) lon:\(String(format: "%.5f", coord.longitude))")
                    await VehicleLocationService.insertLocation(
                        vehicleId: vehicleId,
                        latitude: coord.latitude,
                        longitude: coord.longitude,
                        speed: self?.locationManager.speed
                    )
                } else {
                    print("[LocationTracking] ⚠️ No GPS fix yet — retrying in 5 s")
                    try? await Task.sleep(for: .seconds(5))
                    continue
                }
                try? await Task.sleep(for: .seconds(15))
            }
            print("[LocationTracking] 🛑 Tracking stopped for vehicle \(vehicleId)")
        }
    }

    private func stopLocationTracking() {
        trackingTask?.cancel()
        trackingTask = nil
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
