import Foundation
import Supabase

enum UserService {

    // MARK: - Users

    static func fetchAllUsers() async throws -> [User] {
        do {
            let result: [User] = try await supabase
                .from("users")
                .select()
                .execute()
                .value
            print("[UserService] fetchAllUsers: \(result.count) users")
            return result
        } catch {
            print("[UserService] fetchAllUsers ERROR: \(error)")
            throw error
        }
    }

    static func fetchUser(id: UUID) async throws -> User {
        do {
            let result: User = try await supabase
                .from("users")
                .select()
                .eq("id", value: id)
                .single()
                .execute()
                .value
            print("[UserService] fetchUser(\(id)): OK")
            return result
        } catch {
            print("[UserService] fetchUser(\(id)) ERROR: \(error)")
            throw error
        }
    }

    static func fetchUsersByRole(roleId: UUID) async throws -> [User] {
        do {
            let result: [User] = try await supabase
                .from("users")
                .select()
                .eq("role_id", value: roleId)
                .execute()
                .value
            print("[UserService] fetchUsersByRole(\(roleId)): \(result.count) users")
            return result
        } catch {
            print("[UserService] fetchUsersByRole(\(roleId)) ERROR: \(error)")
            throw error
        }
    }

    static func createUser(_ user: User) async throws {
        do {
            try await supabase
                .from("users")
                .insert(user)
                .execute()
            print("[UserService] createUser(\(user.id)): OK")
        } catch {
            print("[UserService] createUser ERROR: \(error)")
            throw error
        }
    }

    struct CreateUserRequest: Encodable {
        let full_name: String
        let email: String
        let password: String
        let phone: String?
        let role_name: String
        let license_number: String?
    }

    static func createUserViaEdgeFunction(
        fullName: String,
        email: String,
        password: String,
        phone: String?,
        roleName: String,
        licenseNumber: String?
    ) async throws -> Profile {
        let request = CreateUserRequest(
            full_name: fullName,
            email: email,
            password: password,
            phone: phone,
            role_name: roleName,
            license_number: licenseNumber
        )

        let data: Data = try await supabase.functions.invoke(
            "create-user",
            options: FunctionInvokeOptions(body: request)
        )

        // Supabase function returns the created profile as JSON
        return try SupabaseManager.jsonDecoder.decode(Profile.self, from: data)
    }

    static func updateUser(_ user: User) async throws {
        try await supabase
            .from("users")
            .update(user)
            .eq("id", value: user.id)
            .execute()
    }

    static func deleteUser(id: UUID) async throws {
        struct DeleteParams: Encodable {
            let target_user_id: UUID
        }

        try await supabase
            .rpc("delete_user_auth", params: DeleteParams(target_user_id: id))
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
