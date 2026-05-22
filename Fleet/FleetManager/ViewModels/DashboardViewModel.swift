import SwiftUI

@Observable
final class DashboardViewModel {
    //loaded from MockData
    private(set) var vehicles: [Vehicle] = MockData.vehicles
    private(set) var trips: [Trip] = MockData.trips
    private(set) var workOrders: [WorkOrder] = MockData.workOrders
    
    func refreshData() {
        self.vehicles = MockData.vehicles
        self.trips = MockData.trips
        self.workOrders = MockData.workOrders
    }
    
    var totalVehicles: Int { 
        vehicles.count 
    }
    
    var activeTrips: Int { 
        trips.filter { $0.status == .active }.count 
    }
    
    var pendingOrders: Int { 
        trips.filter { $0.status == .scheduled }.count 
    }
    
    var driversOnTrip: Int {
        Set(trips.filter { $0.status == .active }.compactMap { $0.driverId }).count
    }
    
    var recentOrders: [Trip] {
        Array(trips.prefix(3))
    }
    
    var maintenanceVehicles: [Vehicle] {
        vehicles.filter { $0.status == .maintenance }
    }
}
