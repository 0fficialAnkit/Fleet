import SwiftUI

@MainActor
@Observable
final class ProfileViewModel {
    var currentUser: Profile?
    var roleName: String = "Unknown Role"

    var isLoading = false
    var errorMessage: String?

    func loadProfile() async {
        isLoading = true
        errorMessage = nil
        do {
            guard let userId = await SupabaseManager.currentUserId else {
                errorMessage = "Not signed in"
                isLoading = false
                return
            }
            let profile = try await ProfileService.fetchProfile(id: userId)
            self.currentUser = profile
            switch profile.role {
            case "fleet_manager": self.roleName = "Fleet Manager"
            case "driver": self.roleName = "Driver"
            case "maintenance": self.roleName = "Maintenance"
            default: self.roleName = profile.role.capitalized
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func updateProfile(fullName: String, phone: String) async {
        guard var profile = currentUser else { return }
        profile.fullName = fullName
        profile.phone = phone.isEmpty ? nil : phone
        
        isLoading = true
        errorMessage = nil
        do {
            try await ProfileService.updateProfile(profile)
            self.currentUser = profile
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
