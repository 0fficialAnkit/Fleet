import SwiftUI

@MainActor
@Observable
final class EmployeesViewModel {
    private(set) var profiles: [Profile] = []

    var isLoading = false
    var errorMessage: String?
    var isCreatingUser = false

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
    }

    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            profiles = try await ProfileService.fetchAllProfiles()
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
        case "fleet_manager", "fleet manager": return themeModel.analyticsPurple
        case "driver": return themeModel.info
        case "maintenance": return themeModel.warning
        default: return themeModel.textSecondary
        }
    }

    /// NOTE: User creation via Edge Function is disabled for this sprint.
    /// New users (drivers/maintenance staff) must be created directly in Supabase.
    /// Use existing users from public.users for assignment dropdowns.
    func addEmployee(fullName: String, email: String, password: String, phone: String, licenseNumber: String?, role: String) async throws {
        // Edge Function is temporarily disabled per sprint requirements.
        // Existing users in auth.users/public.users are sufficient for demo.
        print("[EmployeesViewModel] addEmployee: Edge Function disabled for this sprint.")
        throw NSError(
            domain: "EmployeesViewModel",
            code: 503,
            userInfo: [NSLocalizedDescriptionKey: "User creation is temporarily disabled. Please add users directly in Supabase dashboard. Existing users are available for assignment."]
        )
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
