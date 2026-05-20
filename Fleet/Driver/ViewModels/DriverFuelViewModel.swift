import SwiftUI

@Observable
final class DriverFuelViewModel {
    private(set) var fuelLogs: [FuelLog] = [] // Typically would load from MockData if it existed, or just keep empty for now.
    
    var fuelEfficiency: Double {
        return 4.2
    }
    
    var totalFuelCost: Double {
        return fuelLogs.reduce(0) { $0 + ($1.fuelCost ?? 0) }
    }
    
    var totalLiters: Double {
        return fuelLogs.reduce(0) { $0 + ($1.litersUsed ?? 0) }
    }

    func addFuelLog(liters: Double, cost: Double, vehicleId: UUID) {
        let newLog = FuelLog(
            id: UUID(),
            vehicleId: vehicleId,
            driverId: nil,
            litersUsed: liters,
            fuelCost: cost,
            recordedAt: Date()
        )
        fuelLogs.insert(newLog, at: 0)
    }
}
