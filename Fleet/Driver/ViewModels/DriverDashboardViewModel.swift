import SwiftUI

@Observable
final class DriverDashboardViewModel {
    // Loaded from MockData
    private(set) var vehicles: [Vehicle] = MockData.vehicles
    private(set) var trips: [Trip] = MockData.trips
    
    // Default vehicle for the driver portal demo
    var vehicle: Vehicle {
        vehicles.first { $0.status == .active } ?? vehicles[0]
    }
    
    // Active trips
    var todaysTrips: [Trip] {
        trips.filter { $0.status == .active || $0.status == .scheduled }
    }
}
