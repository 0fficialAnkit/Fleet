import SwiftUI

@Observable
final class DriverTripsViewModel {
    private(set) var trips: [Trip] = MockData.trips
    
    var sortedTrips: [Trip] {
        trips.sorted(by: { ($0.startTime ?? Date()) < ($1.startTime ?? Date()) })
    }
    
    func startTrip(id: UUID) {
        if let index = trips.firstIndex(where: { $0.id == id }) {
            trips[index].status = .active
            trips[index].startTime = Date()
        }
    }
    
    func endTrip(id: UUID) {
        if let index = trips.firstIndex(where: { $0.id == id }) {
            trips[index].status = .completed
            trips[index].endTime = Date()
        }
    }
}
