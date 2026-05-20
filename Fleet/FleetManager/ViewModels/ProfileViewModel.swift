import SwiftUI

@Observable
final class ProfileViewModel {
    private let users: [User] = MockData.users
    private let roles: [Role] = MockData.roles
    
    var currentUser: User? {
        // Identify and fetch the fleet manager from the database mock
        users.first { user in
            let role = roles.first { $0.id == user.roleId }
            return role?.roleName.lowercased() == "fleet manager"
        }
    }
    
    var roleName: String {
        guard let user = currentUser,
              let role = roles.first(where: { $0.id == user.roleId }) else {
            return "Unknown Role"
        }
        return role.roleName
    }
    
    func logout() {
        // Placeholder for the authentication logout logic
        print("Fleet Manager logged out")
    }
}
