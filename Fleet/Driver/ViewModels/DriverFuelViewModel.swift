import SwiftUI

@MainActor
@Observable
final class DriverFuelViewModel {
    private(set) var fuelLogs: [FuelLog] = []

    var isLoading = false
    var errorMessage: String?
    var currentUserId: UUID?

    var fuelEfficiency: Double {
        guard !fuelLogs.isEmpty else { return 0.0 }
        let totalLiters = fuelLogs.reduce(0) { $0 + ($1.litersUsed ?? 0) }
        return totalLiters > 0 ? Double(fuelLogs.count) * 100.0 / totalLiters : 0.0
    }

    var totalFuelCost: Double {
        return fuelLogs.reduce(0) { $0 + ($1.fuelCost ?? 0) }
    }

    var totalLiters: Double {
        return fuelLogs.reduce(0) { $0 + ($1.litersUsed ?? 0) }
    }

    func setupRealtime() {
        RealtimeManager.shared.addFuelLogsChangeHandler { [weak self] in
            Task { await self?.loadData() }
        }
    }

    func loadData() async {
        guard let userId = currentUserId else { return }
        isLoading = true
        errorMessage = nil
        do {
            fuelLogs = try await FuelLogService.fetchFuelLogs(driverId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func addFuelLog(liters: Double, cost: Double, vehicleId: UUID) {
        guard let userId = currentUserId else { return }
        let newLog = FuelLog(
            id: UUID(),
            vehicleId: vehicleId,
            driverId: userId,
            litersUsed: liters,
            fuelCost: cost,
            recordedAt: Date()
        )
        Task {
            do {
                try await FuelLogService.createFuelLog(newLog)
                await loadData()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
