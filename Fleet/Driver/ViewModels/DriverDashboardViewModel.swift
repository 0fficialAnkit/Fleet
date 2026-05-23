import SwiftUI

@MainActor
@Observable
final class DriverDashboardViewModel {
    private(set) var vehicle: Vehicle?
    private(set) var trips: [Trip] = []

    var isLoading = false
    var errorMessage: String?
    var currentUserId: UUID?

    // Active/scheduled trips for today
    var todaysTrips: [Trip] {
        trips.filter { $0.status == .active || $0.status == .scheduled }
    }

    func loadData() async {
        guard let userId = currentUserId else { return }
        isLoading = true
        errorMessage = nil
        do {
            async let t = TripService.fetchTripsForDriver(driverId: userId)
            async let v = VehicleService.fetchVehicleForDriver(driverId: userId)
            trips = try await t
            vehicle = try await v
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func setupRealtime() {
        let rt = RealtimeManager.shared
        rt.addTripsChangeHandler { [weak self] in Task { await self?.loadData() } }
        rt.addVehiclesChangeHandler { [weak self] in Task { await self?.loadData() } }
    }

    func startTrip(id: UUID, vehicleId: UUID, notes: String) {
        Task {
            do {
                try await TripService.startTrip(id: id)
                let inspection = VehicleInspection(id: UUID(), vehicleId: vehicleId, driverId: currentUserId, tripId: id, inspectionType: .preTrip, notes: notes, createdAt: Date())
                try? await InspectionService.createInspection(inspection)
                await loadData()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func endTrip(id: UUID, vehicleId: UUID, notes: String) {
        Task {
            do {
                try await TripService.endTrip(id: id)
                let inspection = VehicleInspection(id: UUID(), vehicleId: vehicleId, driverId: currentUserId, tripId: id, inspectionType: .postTrip, notes: notes, createdAt: Date())
                try? await InspectionService.createInspection(inspection)
                await loadData()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

enum DriverDestination: Hashable {
    case profile
    case vehicleDetail(Vehicle)
    case tripDetail(Trip)
}
