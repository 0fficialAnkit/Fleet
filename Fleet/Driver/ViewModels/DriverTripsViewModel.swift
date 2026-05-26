import SwiftUI

@MainActor
@Observable
final class DriverTripsViewModel {
    private(set) var trips: [Trip] = []

    var isLoading = false
    var errorMessage: String?
    var currentUserId: UUID?

    var sortedTrips: [Trip] {
        trips.sorted(by: { ($0.startTime ?? Date()) < ($1.startTime ?? Date()) })
    }

    func loadData() async {
        guard let userId = currentUserId else { return }
        isLoading = true
        errorMessage = nil
        do {
            trips = try await TripService.fetchTripsForDriver(driverId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func setupRealtime() {
        RealtimeManager.shared.addTripsChangeHandler { [weak self] in
            Task { await self?.loadData() }
        }
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