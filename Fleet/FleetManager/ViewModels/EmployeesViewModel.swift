import SwiftUI

@Observable
final class EmployeesViewModel {
    private(set) var users: [User] = MockData.users
    private(set) var roles: [Role] = MockData.roles
    
    var employees: [User] {
        users.filter { user in
            let role = getRole(for: user)
            return role?.roleName.lowercased() != "fleet manager"
        }
    }
    
    var drivers: [User] {
        users.filter { getRole(for: $0)?.roleName.lowercased() == "driver" }
    }
    
    var maintenanceStaff: [User] {
        users.filter { getRole(for: $0)?.roleName.lowercased() == "maintenance" }
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
    
    func addEmployee(fullName: String, email: String, phone: String, licenseNumber: String?, roleId: UUID) {
        let newUser = User(
            id: UUID(),
            fullName: fullName,
            email: email,
            passwordHash: "$2b$12$dummy",
            phone: phone,
            licenseNumber: licenseNumber,
            roleId: roleId,
            status: .active,
            createdAt: Date()
        )
        users.append(newUser)
    }
}
