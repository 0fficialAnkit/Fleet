import SwiftUI

@Observable
final class VehiclesViewModel {
    private let vehiclesData: [Vehicle] = MockData.vehicles
    private let users: [User] = MockData.users
    private let tripsData: [Trip] = MockData.trips
    
    var vehicles: [Vehicle] {
        vehiclesData
    }
    
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
}
