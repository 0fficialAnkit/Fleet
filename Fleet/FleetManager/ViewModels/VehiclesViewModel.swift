import SwiftUI

@MainActor
@Observable
final class VehiclesViewModel {
    var vehicles: [Vehicle] = []
    private(set) var users: [User] = []
    private(set) var trips: [Trip] = []

    var isLoading = false
    var errorMessage: String?

    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let v = VehicleService.fetchAllVehicles()
            async let u = UserService.fetchAllUsers()
            async let t = TripService.fetchAllTrips()
            vehicles = try await v
            users = try await u
            trips = try await t
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func getDriver(for driverId: UUID?) -> User? {
        guard let id = driverId else { return nil }
        return users.first { $0.id == id }
    }

    func getPastTrips(for vehicleId: UUID) -> [Trip] {
        return trips.filter { $0.vehicleId == vehicleId && $0.status == .completed }
            .sorted(by: { ($0.endTime ?? Date()) > ($1.endTime ?? Date()) })
    }

    func getStatusColor(_ status: VehicleStatus?) -> Color {
        switch status {
        case .active: return themeModel.activeVehicle
        case .maintenance: return themeModel.maintenanceVehicle
        case .inactive: return themeModel.inactiveVehicle
        case nil: return themeModel.textTertiary
        }
    }

    func addVehicle(make: String, model: String, year: Int, tankCapacity: Double?, mileage: Double?, purchaseDate: Date?, licensePlate: String) {
        let newVehicle = Vehicle(
            id: UUID(),
            make: make,
            model: model,
            year: year,
            vin: nil,
            licensePlate: licensePlate,
            tankCapacity: tankCapacity,
            mileage: mileage,
            purchaseDate: purchaseDate,
            assignedDriverId: nil,
            status: .active
        )
        Task {
            do {
                try await VehicleService.createVehicle(newVehicle)
                await loadData()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func updateVehicle(_ updatedVehicle: Vehicle) {
        Task {
            do {
                try await VehicleService.updateVehicle(updatedVehicle)
                await loadData()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func deleteVehicle(_ vehicle: Vehicle) {
        Task {
            do {
                try await VehicleService.deleteVehicle(id: vehicle.id)
                await loadData()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
