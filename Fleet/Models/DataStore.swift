import Foundation
import Combine

class DataStore: ObservableObject {
    static let shared = DataStore()
    
    private init() {}
    
    @Published var vehicle = Vehicle(
        id: UUID(),
        make: "Ford",
        model: "F-150",
        year: 2024,
        vin: nil,
        licensePlate: "TRK-001",
        assignedDriverId: nil,
        status: .active
    )
    
    @Published var trips: [Trip] = [
        Trip(
            id: UUID(),
            vehicleId: UUID(),
            driverId: UUID(),
            routeId: UUID(),
            startTime: Calendar.current.date(byAdding: .hour, value: 1, to: Date()),
            endTime: nil,
            distance: 42,
            status: .active
        ),
        Trip(
            id: UUID(),
            vehicleId: UUID(),
            driverId: UUID(),
            routeId: UUID(),
            startTime: Calendar.current.date(byAdding: .hour, value: 3, to: Date()),
            endTime: nil,
            distance: 120,
            status: .scheduled
        ),
        Trip(
            id: UUID(),
            vehicleId: UUID(),
            driverId: UUID(),
            routeId: UUID(),
            startTime: Calendar.current.date(byAdding: .hour, value: -2, to: Date()),
            endTime: Calendar.current.date(byAdding: .hour, value: -1, to: Date()),
            distance: 35,
            status: .completed
        )
    ]
    
    @Published var fuelLogs: [FuelLog] = [
        FuelLog(
            id: UUID(),
            vehicleId: UUID(),
            driverId: UUID(),
            litersUsed: 48.0,
            fuelCost: 4200.0,
            recordedAt: Date().addingTimeInterval(-86400)
        ),
        FuelLog(
            id: UUID(),
            vehicleId: UUID(),
            driverId: UUID(),
            litersUsed: 35.0,
            fuelCost: 3000.0,
            recordedAt: Date().addingTimeInterval(-172800)
        )
    ]
}
