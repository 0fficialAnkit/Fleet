import SwiftUI

@MainActor
@Observable
final class VehiclesViewModel {
    var vehicles: [Vehicle] = []
    private(set) var profiles: [Profile] = []
    private(set) var trips: [Trip] = []

    var isLoading = false
    var errorMessage: String?

    func setupRealtime() {
        let rt = RealtimeManager.shared
        rt.addVehiclesChangeHandler { [weak self] in Task { await self?.loadData() } }
        rt.addProfilesChangeHandler { [weak self] in Task { await self?.loadData() } }
        rt.addTripsChangeHandler { [weak self] in Task { await self?.loadData() } }
    }

    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let v = VehicleService.fetchAllVehicles()
            async let p = ProfileService.fetchAllProfiles()
            async let t = TripService.fetchAllTrips()
            vehicles = try await v
            profiles = try await p
            trips = try await t
        } catch {
            errorMessage = error.localizedDescription
        }
        
        // --- INJECT MOCK DATA FOR TESTING T4-19 ---
        let mockVehicleId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let mockVehicle = Vehicle(
            id: mockVehicleId,
            make: "Honda",
            model: "Activa (Mock)",
            year: 2024,
            vin: "MOCK1234",
            licensePlate: "MH-12-AB-1234",
            tankCapacity: 5,
            mileage: 45,
            purchaseDate: Date(),
            assignedDriverId: nil,
            adminId: nil,
            status: .active,
            vehicleType: .twoWheeler
        )
        
        let mockTrip = Trip(
            id: UUID(),
            vehicleId: mockVehicleId,
            driverId: nil,
            routeId: nil,
            startTime: Date().addingTimeInterval(-86400 * 2),
            endTime: Date(),
            distance: 3100.0,
            status: .completed,
            orderType: .pickUpAndDrop,
            createdAt: Date()
        )
        
        if !vehicles.contains(where: { $0.vin == "MOCK1234" }) {
            vehicles.append(mockVehicle)
            trips.append(mockTrip)
        }
        // -------------------------------------------
        
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

    func getStatusColor(_ status: VehicleStatus?) -> Color {
        switch status {
        case .active: return Color.green
        case .maintenance: return Color.yellow
        case .inactive: return Color(.tertiaryLabel)
        case nil: return Color(.tertiaryLabel)
        }
    }

    func addVehicle(make: String, model: String, year: Int, tankCapacity: Double?, mileage: Double?, licensePlate: String, vehicleType: VehicleType) async throws {
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