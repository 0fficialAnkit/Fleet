import Foundation
import Supabase

/// ProfileService bridges the existing `users` + `roles` tables
/// to produce `Profile` objects used by ViewModels across the app.
enum ProfileService {

    // MARK: - Internal: role lookup cache

    private static var cachedRoles: [Role]?

    private static func allRoles() async throws -> [Role] {
        if let cached = cachedRoles { return cached }
        let roles: [Role] = try await supabase.from("roles").select().execute().value
        cachedRoles = roles
        return roles
    }

    /// Convert a role_name like "Fleet Manager" to the app-internal string "fleet_manager"
    private static func normalizeRoleName(_ roleName: String) -> String {
        switch roleName.lowercased() {
        case "fleet manager", "fleet_manager", "manager": return "fleet_manager"
        case "driver": return "driver"
        case "maintenance", "maintenance staff": return "maintenance"
        default: return roleName.lowercased().replacingOccurrences(of: " ", with: "_")
        }
    }

    private static func toProfile(user: User, roles: [Role]) -> Profile {
        let roleName = roles.first(where: { $0.id == user.roleId })?.roleName ?? "unknown"
        return Profile(
            id: user.id,
            fullName: user.fullName,
            email: user.email,
            phone: user.phone,
            licenseNumber: user.licenseNumber,
            role: normalizeRoleName(roleName),
            status: user.status?.rawValue ?? "active",
            createdAt: user.createdAt
        )
    }

    // MARK: - Fetch single profile

    static func fetchProfile(id: UUID) async throws -> Profile {
        do {
            let user: User = try await supabase
                .from("users")
                .select()
                .eq("id", value: id)
                .single()
                .execute()
                .value
            let roles = try await allRoles()
            let profile = toProfile(user: user, roles: roles)
            print("[ProfileService] fetchProfile(\(id)): role=\(profile.role)")
            return profile
        } catch {
            print("[ProfileService] fetchProfile(\(id)) ERROR: \(error)")
            throw error
        }
    }

    // MARK: - Fetch all profiles

    static func fetchAllProfiles() async throws -> [Profile] {
        do {
            let users: [User] = try await supabase
                .from("users")
                .select()
                .execute()
                .value
            let roles = try await allRoles()
            let profiles = users.map { toProfile(user: $0, roles: roles) }
            print("[ProfileService] fetchAllProfiles: \(profiles.count) profiles")
            return profiles
        } catch {
            print("[ProfileService] fetchAllProfiles ERROR: \(error)")
            throw error
        }
    }

    // MARK: - Fetch profiles by role

    static func fetchProfilesByRole(role: String) async throws -> [Profile] {
        let roles = try await allRoles()
        // Find the role ID that matches the requested normalized role
        let matchingRoleIds = roles.filter { normalizeRoleName($0.roleName) == role }.map(\.id)
        guard !matchingRoleIds.isEmpty else { return [] }

        var allMatching: [Profile] = []
        for roleId in matchingRoleIds {
            let users: [User] = try await supabase
                .from("users")
                .select()
                .eq("role_id", value: roleId)
                .execute()
                .value
            allMatching.append(contentsOf: users.map { toProfile(user: $0, roles: roles) })
        }
        return allMatching
    }

    // MARK: - Update profile (writes back to users table)

    static func updateProfile(_ profile: Profile) async throws {
        struct UserUpdate: Encodable {
            let fullName: String
            let email: String
            let phone: String?
            let licenseNumber: String?

            enum CodingKeys: String, CodingKey {
                case fullName = "full_name"
                case email
                case phone
                case licenseNumber = "license_number"
            }
        }

        let update = UserUpdate(
            fullName: profile.fullName,
            email: profile.email,
            phone: profile.phone,
            licenseNumber: profile.licenseNumber
        )

        try await supabase
            .from("users")
            .update(update)
            .eq("id", value: profile.id)
            .execute()
    }

    // MARK: - Create user via Edge Function (manager only)

    static func createUserViaEdgeFunction(
        email: String,
        password: String,
        fullName: String,
        phone: String?,
        licenseNumber: String?,
        role: String
    ) async throws -> UUID {
        struct CreateUserRequest: Encodable {
            let email: String
            let password: String
            let fullName: String
            let phone: String?
            let licenseNumber: String?
            let role: String
        }

        struct CreateUserResponse: Decodable {
            let success: Bool?
            let userId: UUID?
            let message: String?
            let error: String?
        }

        let body = CreateUserRequest(
            email: email,
            password: password,
            fullName: fullName,
            phone: phone,
            licenseNumber: licenseNumber,
            role: role
        )

        let response: CreateUserResponse = try await supabase.functions
            .invoke(
                "create-user",
                options: .init(body: body)
            )

        if let error = response.error {
            throw NSError(domain: "ProfileService", code: 400, userInfo: [NSLocalizedDescriptionKey: error])
        }

        guard let userId = response.userId else {
            throw NSError(domain: "ProfileService", code: 500, userInfo: [NSLocalizedDescriptionKey: "No user ID returned"])
        }

        return userId
    }
}
