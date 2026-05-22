import SwiftUI

@MainActor
@Observable
final class EmployeesViewModel {
    private(set) var users: [User] = []
    private(set) var roles: [Role] = []

    var isLoading = false
    var errorMessage: String?

    var employees: [User] {
        users.filter { user in
            let role = getRole(for: user)
            return role?.roleName.lowercased() != "fleet_manager"
        }
    }

    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let u = UserService.fetchAllUsers()
            async let r = UserService.fetchAllRoles()
            users = try await u
            roles = try await r
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func getRole(for user: User) -> Role? {
        roles.first { $0.id == user.roleId }
    }

    func getIcon(for roleName: String) -> String {
        switch roleName.lowercased() {
        case "fleet_manager": return "person.badge.shield.checkmark.fill"
        case "driver": return "steeringwheel"
        case "maintenance": return "wrench.and.screwdriver.fill"
        default: return "person.fill"
        }
    }

    func getColor(for roleName: String) -> Color {
        switch roleName.lowercased() {
        case "fleet_manager": return themeModel.analyticsPurple
        case "driver": return themeModel.info
        case "maintenance": return themeModel.warning
        default: return themeModel.textSecondary
        }
    }

    func addEmployee(fullName: String, email: String, phone: String, licenseNumber: String?, roleId: UUID, passwordHash: String) {
        let newUser = User(
            id: UUID(),
            fullName: fullName,
            email: email,
            passwordHash: passwordHash.isEmpty ? "$2b$12$placeholder" : passwordHash,
            phone: phone,
            licenseNumber: licenseNumber,
            roleId: roleId,
            status: .active,
            createdAt: Date()
        )
        Task {
            do {
                try await UserService.createUser(newUser)
                await loadData()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func deleteEmployee(_ user: User) {
        Task {
            do {
                try await UserService.deleteUser(id: user.id)
                await loadData()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func updateEmployee(_ updatedUser: User) {
        Task {
            do {
                try await UserService.updateUser(updatedUser)
                await loadData()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
