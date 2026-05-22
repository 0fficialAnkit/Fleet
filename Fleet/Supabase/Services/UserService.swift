import Foundation
import Supabase

enum UserService {

    // MARK: - Users

    static func fetchAllUsers() async throws -> [User] {
        try await supabase
            .from("users")
            .select()
            .execute()
            .value
    }

    static func fetchUser(id: UUID) async throws -> User {
        try await supabase
            .from("users")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }

    static func fetchUsersByRole(roleId: UUID) async throws -> [User] {
        try await supabase
            .from("users")
            .select()
            .eq("role_id", value: roleId)
            .execute()
            .value
    }

    static func createUser(_ user: User) async throws {
        try await supabase
            .from("users")
            .insert(user)
            .execute()
    }

    static func updateUser(_ user: User) async throws {
        try await supabase
            .from("users")
            .update(user)
            .eq("id", value: user.id)
            .execute()
    }

    static func deleteUser(id: UUID) async throws {
        try await supabase
            .from("users")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Roles

    static func fetchAllRoles() async throws -> [Role] {
        try await supabase
            .from("roles")
            .select()
            .execute()
            .value
    }

    static func fetchRole(id: UUID) async throws -> Role {
        try await supabase
            .from("roles")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }
}
