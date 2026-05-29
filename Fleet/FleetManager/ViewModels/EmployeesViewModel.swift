import SwiftUI

@MainActor
@Observable
final class EmployeesViewModel {
    private(set) var profiles: [Profile] = []
    private(set) var trips:   [Trip]   = []

    var isLoading = false
    var errorMessage: String?
    var isCreatingUser = false

    /// IDs of drivers currently on an active trip
    var activeDriverIds: Set<UUID> {
        Set(trips.filter { $0.status == .active }.compactMap { $0.driverId })
    }

    /// All non-manager profiles
    var employees: [Profile] {
        profiles.filter { $0.role != "fleet_manager" }
    }

    func setupRealtime() {
        RealtimeManager.shared.addUsersChangeHandler { [weak self] in
            Task { await self?.loadData() }
        }
        RealtimeManager.shared.addProfilesChangeHandler { [weak self] in
            Task { await self?.loadData() }
        }
        RealtimeManager.shared.addTripsChangeHandler { [weak self] in
            Task { await self?.loadData() }
        }
    }

    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let p = ProfileService.fetchAllProfiles()
            async let t = TripService.fetchAllTrips()
            profiles = try await p
            trips    = try await t
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func getRole(for profile: Profile) -> String {
        switch profile.role {
        case "fleet_manager": return "Fleet Manager"
        case "driver": return "Driver"
        case "maintenance": return "Maintenance"
        default: return "Unknown"
        }
    }

    func getIcon(for roleName: String) -> String {
        switch roleName.lowercased() {
        case "fleet_manager", "fleet manager": return "person.badge.shield.checkmark.fill"
        case "driver": return "steeringwheel"
        case "maintenance": return "wrench.and.screwdriver.fill"
        default: return "person.fill"
        }
    }

    func getColor(for roleName: String) -> Color {
        switch roleName.lowercased() {
        case "fleet_manager", "fleet manager": return Color.purple
        case "driver": return Color.blue
        case "maintenance": return Color.orange
        default: return Color.secondary
        }
    }

    func addEmployee(fullName: String, email: String, password: String, phone: String, licenseNumber: String?, role: String) async throws {
        isCreatingUser = true
        defer { isCreatingUser = false }

        _ = try await ProfileService.createUserLocally(
            email: email,
            password: password,
            fullName: fullName,
            phone: phone,
            licenseNumber: licenseNumber,
            role: role
        )

        await loadData()
    }

    func deleteEmployee(_ profile: Profile) {
        Task {
            do {
                try await UserService.deleteUser(id: profile.id)
                await loadData()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}