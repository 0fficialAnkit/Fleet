import SwiftUI

@Observable
final class VehiclesViewModel {
    var vehicles: [Vehicle] = MockData.vehicles
    private let users: [User] = MockData.users
    private let tripsData: [Trip] = MockData.trips
    
    func getDriver(for driverId: UUID?) -> User? {
        guard let id = driverId else { return nil }
        return users.first { $0.id == id }
    }
    
    func getPastTrips(for vehicleId: UUID) -> [Trip] {
        return tripsData.filter { $0.vehicleId == vehicleId && $0.status == .completed }
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
    
    func refreshData() {
        self.vehicles = MockData.vehicles
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
        MockData.vehicles.append(newVehicle)
        refreshData()
        NotificationCenter.default.post(name: NSNotification.Name("VehiclesUpdated"), object: nil)
    }
    
    func updateVehicle(_ updatedVehicle: Vehicle) {
        if let index = MockData.vehicles.firstIndex(where: { $0.id == updatedVehicle.id }) {
            MockData.vehicles[index] = updatedVehicle
            refreshData()
            NotificationCenter.default.post(name: NSNotification.Name("VehiclesUpdated"), object: nil)
        }
    }
    
    func deleteVehicle(_ vehicle: Vehicle) {
        MockData.vehicles.removeAll { $0.id == vehicle.id }
        refreshData()
        NotificationCenter.default.post(name: NSNotification.Name("VehiclesUpdated"), object: nil)
    }
}
