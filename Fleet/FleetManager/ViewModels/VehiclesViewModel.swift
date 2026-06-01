import SwiftUI

@MainActor
@Observable
final class VehiclesViewModel {
    var vehicles: [Vehicle] = []
    private(set) var profiles: [Profile] = []
    private(set) var trips: [Trip] = []

    var isLoading = false
    var errorMessage: String?

    func setupRealtime(adminId: UUID? = nil) {
        let rt = RealtimeManager.shared
        rt.addVehiclesChangeHandler { [weak self] in Task { await self?.loadData(adminId: adminId) } }
        rt.addProfilesChangeHandler { [weak self] in Task { await self?.loadData(adminId: adminId) } }
        rt.addTripsChangeHandler { [weak self] in Task { await self?.loadData(adminId: adminId) } }
    }

    func loadData(adminId: UUID? = nil) async {
        isLoading = true
        errorMessage = nil
        do {
            async let v = VehicleService.fetchAllVehicles()
            async let p = ProfileService.fetchAllProfiles()
            async let t = TripService.fetchAllTrips()
            let allVehicles = try await v
            profiles = try await p
            trips = try await t
            
            if let adminId = adminId {
                vehicles = allVehicles.filter { $0.adminId == adminId }
            } else {
                vehicles = allVehicles
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }

    func getDriver(for driverId: UUID?) -> Profile? {
        guard let id = driverId else { return nil }
        return profiles.first { $0.id == id }
    }

    func getPastTrips(for vehicleId: UUID) -> [Trip] {
        return trips.filter { $0.vehicleId == vehicleId && $0.status == .completed }
            .sorted(by: { ($0.endTime ?? Date()) > ($1.endTime ?? Date()) })
    }
    
    func getTotalDistance(for vehicleId: UUID) -> Double {
        let vehicleTrips = trips.filter { $0.vehicleId == vehicleId && $0.status == .completed }
        return vehicleTrips.reduce(0) { $0 + ($1.distance ?? 0) }
    }

    // MARK: - Usage Report Helpers
    
    func getTripsForUsage(vehicleId: UUID, startDate: Date, endDate: Date) -> [Trip] {
        return trips.filter { trip in
            guard trip.vehicleId == vehicleId, trip.status == .completed, let end = trip.endTime else { return false }
            return end >= startDate && end <= endDate
        }
    }
    
    func calculateTotalDistance(trips: [Trip]) -> Double {
        return trips.reduce(0) { $0 + ($1.distance ?? 0) }
    }
    
    func calculateIdleTimeHours(trips: [Trip], startDate: Date, endDate: Date) -> Double {
        let totalTimeInterval = endDate.timeIntervalSince(startDate)
        let totalHours = max(0, totalTimeInterval / 3600.0)
        
        let activeSeconds = trips.reduce(0.0) { sum, trip in
            if let start = trip.startTime, let end = trip.endTime {
                return sum + max(0, end.timeIntervalSince(start))
            }
            return sum
        }
        let activeHours = activeSeconds / 3600.0
        
        return max(0, totalHours - activeHours)
    }
    
    func generateUsageInsight(distance: Double, tripsCount: Int, idleHours: Double, periodDays: Double) -> (status: String, description: String, color: Color) {
        let distancePerDay = periodDays > 0 ? distance / periodDays : distance
        let tripsPerDay = periodDays > 0 ? Double(tripsCount) / periodDays : Double(tripsCount)
        
        if distancePerDay < 10 && tripsPerDay < 0.5 {
            return ("Underused", "This vehicle has very low activity and high idle time. Consider reallocating it.", .orange)
        } else if distancePerDay > 300 || tripsPerDay > 10 {
            return ("Overused", "This vehicle is seeing heavy usage. It may require more frequent maintenance.", .red)
        } else {
            return ("Normal", "Vehicle usage is within expected parameters.", .green)
        }
    }

    func getVehicleStatusText(for vehicle: Vehicle) -> String {
        if vehicle.status == .maintenance {
            return "In Service"
        } else if trips.contains(where: { $0.vehicleId == vehicle.id && $0.status == .active }) {
            return "On Trip"
        } else if vehicle.status == .active {
            return "Available"
        } else {
            return vehicle.status?.rawValue.capitalized ?? "Unknown"
        }
    }
    
    func getVehicleStatusColor(for vehicle: Vehicle) -> Color {
        if vehicle.status == .maintenance {
            return Color.red // Undergoing service / maintenance
        } else if trips.contains(where: { $0.vehicleId == vehicle.id && $0.status == .active }) {
            return Color.green // On an active trip
        } else if vehicle.status == .active {
            return Color.orange // Available / Idle
        } else {
            return Color(.tertiaryLabel)
        }
    }

    func addVehicle(make: String, model: String, year: Int, tankCapacity: Double?, mileage: Double?, licensePlate: String, vehicleType: VehicleType, adminId: UUID? = nil) async throws {
        print("[VehiclesViewModel] addVehicle: make=\(make) model=\(model) plate=\(licensePlate) type=\(vehicleType)")
        do {
            try await VehicleService.createVehicle(
                make: make,
                model: model,
                year: year,
                vin: nil,
                licensePlate: licensePlate,
                tankCapacity: tankCapacity,
                mileage: mileage,
                assignedDriverId: nil,   // Always nil on creation — assign via driver selection
                adminId: adminId,
                status: .active,
                vehicleType: vehicleType
            )
            print("[VehiclesViewModel] addVehicle: success, reloading...")
            await loadData()
        } catch {
            print("[VehiclesViewModel] addVehicle ERROR: \(error)")
            throw error
        }
    }

    func updateVehicle(_ updatedVehicle: Vehicle) async throws {
        do {
            try await VehicleService.updateVehicle(updatedVehicle)
            await loadData()
        } catch {
            print("[VehiclesViewModel] updateVehicle ERROR: \(error)")
            throw error
        }
    }

    func deleteVehicle(_ vehicle: Vehicle) async throws {
        do {
            try await VehicleService.deleteVehicle(id: vehicle.id)
            await loadData()
        } catch {
            print("[VehiclesViewModel] deleteVehicle ERROR: \(error)")
            throw error
        }
    }
}