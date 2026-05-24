import SwiftUI

@Observable
final class OrdersViewModel {
    private(set) var trips: [Trip] = MockData.trips
    var routes: [Route] { MockData.routes }
    
    func refreshData() {
        self.trips = MockData.trips
    }
    
    func getStatusColor(for status: TripStatus?) -> Color {
        switch status {
        case .scheduled: return themeModel.info
        case .active: return themeModel.warning
        case .completed: return themeModel.success
        case .cancelled: return themeModel.danger
        case .none: return themeModel.textDisabled
        }
    }
    
    func addTrip(vehicleId: UUID, driverId: UUID, routeId: UUID?, startTime: Date, orderType: OrderType) {
        let newTrip = Trip(
            id: UUID(),
            vehicleId: vehicleId,
            driverId: driverId,
            routeId: routeId,
            startTime: startTime,
            endTime: startTime.addingTimeInterval(3600 * 2), // Default 2 hours duration
            distance: Double.random(in: 10...150),
            status: .scheduled,
            orderType: orderType
        )
        MockData.trips.insert(newTrip, at: 0)
        refreshData()
     }
     
     func deleteTrip(_ trip: Trip) {
         MockData.trips.removeAll { $0.id == trip.id }
         refreshData()
     }
}
