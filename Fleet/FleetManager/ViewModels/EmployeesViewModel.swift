import SwiftUI

@Observable
final class EmployeesViewModel {
    private(set) var users: [User] = MockData.users
    private(set) var roles: [Role] = MockData.roles
    
    var employees: [User] {
        // Return all users except the Fleet Manager
        users.filter { user in
            let role = getRole(for: user)
            return role?.roleName.lowercased() != "fleet manager"
        }
    }
    
    func getRole(for user: User) -> Role? {
        roles.first { $0.id == user.roleId }
    }
    
    func getIcon(for roleName: String) -> String {
        switch roleName.lowercased() {
        case "fleet manager": return "person.badge.shield.checkmark.fill"
        case "driver": return "steeringwheel"
        case "maintenance": return "wrench.and.screwdriver.fill"
        default: return "person.fill"
        }
    }
    
    func getColor(for roleName: String) -> Color {
        switch roleName.lowercased() {
        case "fleet manager": return themeModel.analyticsPurple
        case "driver": return themeModel.info
        case "maintenance": return themeModel.warning
        default: return themeModel.textSecondary
        }
    }
    
    func refreshData() {
        self.users = MockData.users
    }

    func addEmployee(fullName: String, email: String, phone: String, licenseNumber: String?, roleId: UUID, passwordHash: String) {
        let newUser = User(
            id: UUID(),
            fullName: fullName,
            email: email,
            passwordHash: passwordHash.isEmpty ? "$2b$12$dummy" : passwordHash,
            phone: phone,
            licenseNumber: licenseNumber,
            roleId: roleId,
            status: .active,
            createdAt: Date()
        )
        MockData.users.append(newUser)
        refreshData()
    }
    
    func deleteEmployee(_ user: User) {
        MockData.users.removeAll { $0.id == user.id }
        refreshData()
    }
    
    func updateEmployee(_ updatedUser: User) {
        if let index = MockData.users.firstIndex(where: { $0.id == updatedUser.id }) {
            MockData.users[index] = updatedUser
            refreshData()
        }
    }
}
