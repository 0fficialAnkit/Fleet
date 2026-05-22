import SwiftUI

@MainActor
@Observable
final class ProfileViewModel {
    var currentUser: User?
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
            let user = try await UserService.fetchUser(id: userId)
            self.currentUser = user
            let role = try await UserService.fetchRole(id: user.roleId)
            self.roleName = role.roleName
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
