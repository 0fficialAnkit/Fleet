import SwiftUI

@MainActor
@Observable
final class VehiclesViewModel {
    var vehicles: [Vehicle] = []
    private(set) var profiles: [Profile] = []
    private(set) var trips: [Trip] = []

    var isLoading = false
    var errorMessage: String?

    func setupRealtime() {
        let rt = RealtimeManager.shared
        rt.addVehiclesChangeHandler { [weak self] in Task { await self?.loadData() } }
        rt.addProfilesChangeHandler { [weak self] in Task { await self?.loadData() } }
        rt.addTripsChangeHandler { [weak self] in Task { await self?.loadData() } }
    }

    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let v = VehicleService.fetchAllVehicles()
            async let p = ProfileService.fetchAllProfiles()
            async let t = TripService.fetchAllTrips()
            vehicles = try await v
            profiles = try await p
            trips = try await t
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func getDriver(for driverId: UUID?) -> Profile? {
        guard let id = driverId else { return nil }
        return profiles.first { $0.id == id }
    }

    func getPastTrips(for vehicleId: UUID) -> [Trip] {
        return trips.filter { $0.vehicleId == vehicleId && $0.status == .completed }
            .sorted(by: { ($0.endTime ?? Date()) > ($1.endTime ?? Date()) })
    }

    func getStatusColor(_ status: VehicleStatus?) -> Color {
        switch status {
        case .active: return Color.green
        case .maintenance: return Color.yellow
        case .inactive: return Color(UIColor.tertiaryLabel)
        case nil: return Color(UIColor.tertiaryLabel)
        }
    }

    func addVehicle(make: String, model: String, year: Int, tankCapacity: Double?, mileage: Double?, licensePlate: String) async throws {
        print("[VehiclesViewModel] addVehicle: make=\(make) model=\(model) plate=\(licensePlate)")
        do {
            try await VehicleService.createVehicle(
                make: make,
                model: model,
                year: year,
                vin: nil,
                licensePlate: licensePlate,
                tankCapacity: tankCapacity,
                mileage: mileage,
                assignedDriverId: nil,   // Always nil on creation — assign via driver selection
                status: .active
            )
            print("[VehiclesViewModel] addVehicle: success, reloading...")
            await loadData()
        } catch {
            print("[VehiclesViewModel] addVehicle ERROR: \(error)")
            throw error
        }
    }

    func updateVehicle(_ updatedVehicle: Vehicle) async throws {
        do {
            try await VehicleService.updateVehicle(updatedVehicle)
            await loadData()
        } catch {
            print("[VehiclesViewModel] updateVehicle ERROR: \(error)")
            throw error
        }
    }

    func deleteVehicle(_ vehicle: Vehicle) async throws {
        do {
            try await VehicleService.deleteVehicle(id: vehicle.id)
            await loadData()
        } catch {
            print("[VehiclesViewModel] deleteVehicle ERROR: \(error)")
            throw error
        }
    }
}
