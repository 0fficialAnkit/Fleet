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
            isOnDuty: user.isOnDuty,
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

    /// Fetches profiles. When `managerId` is provided only employees created
    /// by that manager are returned. Pass nil to get everyone (admin use only).
    static func fetchAllProfiles(managerId: UUID? = nil) async throws -> [Profile] {
        do {
            let users: [User]
            if let managerId {
                users = try await supabase
                    .from("users")
                    .select()
                    .or("created_by_manager_id.eq.\(managerId.uuidString),created_by_manager_id.is.null")
                    .execute()
                    .value
            } else {
                users = try await supabase
                    .from("users")
                    .select()
                    .execute()
                    .value
            }
            let roles = try await allRoles()
            let profiles = users.map { toProfile(user: $0, roles: roles) }
            print("[ProfileService] fetchAllProfiles(managerId:\(managerId?.uuidString.prefix(6) ?? "nil")): \(profiles.count) profiles")
            return profiles
        } catch {
            print("[ProfileService] fetchAllProfiles ERROR: \(error)")
            throw error
        }
    }

    // MARK: - Fetch profiles by role

    /// Fetches profiles matching a role. When `managerId` is provided only users
    /// created by that manager are returned.
    static func fetchProfilesByRole(role: String, managerId: UUID? = nil, onlyOnDuty: Bool = false) async throws -> [Profile] {
        let roles = try await allRoles()
        // Find the role ID that matches the requested normalized role
        let matchingRoleIds = roles.filter { normalizeRoleName($0.roleName) == role }.map(\.id)
        guard !matchingRoleIds.isEmpty else { return [] }

        var allMatching: [Profile] = []
        for roleId in matchingRoleIds {
            var query = supabase
                .from("users")
                .select()
                .eq("role_id", value: roleId)
            if let managerId {
                query = query.or("created_by_manager_id.eq.\(managerId.uuidString),created_by_manager_id.is.null")
            }
            if onlyOnDuty {
                query = query.eq("is_on_duty", value: true)
            }
            let users: [User] = try await query.execute().value
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
            let userStatus: String?
            let isOnDuty: Bool?

            enum CodingKeys: String, CodingKey {
                case fullName    = "full_name"
                case email
                case phone
                case licenseNumber = "license_number"
                case userStatus    = "status"
                case isOnDuty      = "is_on_duty"
            }
        }

        let update = UserUpdate(
            fullName:      profile.fullName,
            email:         profile.email,
            phone:         profile.phone,
            licenseNumber: profile.licenseNumber,
            userStatus:    profile.status,
            isOnDuty:      profile.isOnDuty
        )

        try await supabase
            .from("users")
            .update(update)
            .eq("id", value: profile.id)
            .execute()
    }

    // MARK: - Create user via Edge Function (manager only)

    static func createUserLocally(
        email: String,
        password: String,
        fullName: String,
        phone: String?,
        licenseNumber: String?,
        role: String,
        createdByManagerId: UUID? = nil
    ) async throws -> UUID {

        // 1. Fetch role_id
        let roles = try await allRoles()
        let normalizedRole = normalizeRoleName(role)
        guard let roleId = roles.first(where: { normalizeRoleName($0.roleName) == normalizedRole })?.id else {
            throw NSError(domain: "ProfileService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Role not found"])
        }

        // 2. Prepare user metadata
        var userData: [String: Any] = [
            "full_name": fullName,
            "fullName": fullName,
            "role": normalizedRole,
            "role_id": roleId.uuidString
        ]
        if let phone = phone, !phone.isEmpty { userData["phone"] = phone }
        if let license = licenseNumber, !license.isEmpty { userData["license_number"] = license }

        // 3. Make direct REST API call to /auth/v1/signup to bypass Edge Function
        // and avoid overriding the local SupabaseClient session.
        let url = supabaseURL.appendingPathComponent("auth/v1/signup")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "email": email,
            "password": password,
            "data": userData
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "ProfileService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        if !(200...299).contains(httpResponse.statusCode) {
            let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let msg = errorJson?["msg"] as? String ?? "Unknown database error"
            throw NSError(domain: "ProfileService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let newUserId: UUID
        if let userDict = json?["user"] as? [String: Any],
           let idString = userDict["id"] as? String,
           let parsedId = UUID(uuidString: idString) {
            newUserId = parsedId
        } else if let idString = json?["id"] as? String,
                  let parsedId = UUID(uuidString: idString) {
            newUserId = parsedId
        } else {
            throw NSError(domain: "ProfileService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not parse new user ID"])
        }

        // 4. Upsert into public.users using an explicit struct that matches
        //    the exact DB column names — avoids silent failures from mismatches.
        struct UserInsertPayload: Encodable {
            let id: UUID
            let full_name: String
            let email: String
            let password_hash: String
            let phone: String?
            let license_number: String?
            let role_id: UUID
            let status: String
            let created_by_manager_id: UUID?
        }

        let payload = UserInsertPayload(
            id: newUserId,
            full_name: fullName,
            email: email,
            password_hash: "auth_managed",
            phone: phone?.isEmpty == false ? phone : nil,
            license_number: licenseNumber?.isEmpty == false ? licenseNumber : nil,
            role_id: roleId,
            status: "active",
            created_by_manager_id: createdByManagerId
        )

        do {
            try await supabase
                .from("users")
                .upsert(payload, onConflict: "id")
                .execute()
            print("[ProfileService] Upserted user \(newUserId) created_by_manager_id=\(createdByManagerId?.uuidString ?? "nil")")
        } catch {
            print("[ProfileService] Upsert failed: \(error)")
            // Fallback: plain update to set created_by_manager_id on existing row
            struct ManagerPatch: Encodable { let created_by_manager_id: UUID? }
            _ = try? await supabase
                .from("users")
                .update(ManagerPatch(created_by_manager_id: createdByManagerId))
                .eq("id", value: newUserId)
                .execute()
        }

        return newUserId
    }

    // MARK: - Share Credentials

    static func invokeShareCredentials(for profile: Profile) async throws {
        struct ShareCredentialsRequest: Encodable {
            let userId: String
            let email: String
            let fullName: String
        }

        let request = ShareCredentialsRequest(
            userId: profile.id.uuidString,
            email: profile.email,
            fullName: profile.fullName
        )

        do {
            try await supabase.functions.invoke(
                "share-credentials",
                options: FunctionInvokeOptions(body: request)
            )
            print("[ProfileService] invokeShareCredentials success")
        } catch {
            print("[ProfileService] invokeShareCredentials error: \(error)")
            throw error
        }
    }
}
