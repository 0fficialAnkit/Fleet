import Foundation
import Supabase
import SwiftUI
import Observation

@MainActor
@Observable
class AuthViewModel {
    var isAuthenticated = false
    var currentUser: Auth.User?
    var currentProfile: Profile?
    var errorMessage: String?
    var isLoading = false
    var isSessionChecked = false

    /// Role name derived from the users + roles tables ("fleet_manager", "driver", "maintenance")
    var resolvedRoleName: String? {
        currentProfile?.role
    }

    func fetchProfile() async {
        guard let user = currentUser else {
            print("[AuthViewModel] fetchProfile: no currentUser, skipping")
            return
        }
        print("[AuthViewModel] fetchProfile: fetching for userId=\(user.id)")
        do {
            // Query the existing users table
            let userRow: User = try await supabase
                .from("users")
                .select()
                .eq("id", value: user.id)
                .single()
                .execute()
                .value

            print("[AuthViewModel] fetchProfile: found user '\(userRow.fullName)' roleId=\(userRow.roleId)")

            // Query the role name
            let roleName: String
            let role: Role = try await supabase
                .from("roles")
                .select()
                .eq("id", value: userRow.roleId)
                .single()
                .execute()
                .value
            roleName = role.roleName
            print("[AuthViewModel] fetchProfile: roleName='\(roleName)'")

            // Normalize role name for routing
            let normalizedRole: String
            switch roleName.lowercased() {
            case "fleet manager", "fleet_manager", "manager": normalizedRole = "fleet_manager"
            case "driver": normalizedRole = "driver"
            case "maintenance", "maintenance staff": normalizedRole = "maintenance"
            default: normalizedRole = roleName.lowercased().replacingOccurrences(of: " ", with: "_")
            }
            print("[AuthViewModel] fetchProfile: normalizedRole='\(normalizedRole)'")

            self.currentProfile = Profile(
                id: userRow.id,
                fullName: userRow.fullName,
                email: userRow.email,
                phone: userRow.phone,
                licenseNumber: userRow.licenseNumber,
                role: normalizedRole,
                status: userRow.status?.rawValue ?? "active",
                createdAt: userRow.createdAt
            )
            print("[AuthViewModel] fetchProfile: profile set successfully")
        } catch {
            print("[AuthViewModel] fetchProfile ERROR: \(error)")
            self.errorMessage = "Failed to load user profile. Ensure your account exists in the users table with a valid role_id."
        }
    }

    func checkUserSession() async {
        print("[AuthViewModel] checkUserSession: checking...")
        do {
            let session = try await supabase.auth.session
            self.currentUser = session.user
            print("[AuthViewModel] checkUserSession: session found for userId=\(session.user.id)")
            await fetchProfile()
            self.isAuthenticated = true
            print("[AuthViewModel] checkUserSession: authenticated, role=\(self.resolvedRoleName ?? "nil")")
        } catch {
            print("[AuthViewModel] checkUserSession: no active session — \(error)")
            self.isAuthenticated = false
            self.currentUser = nil
            self.currentProfile = nil
        }
        self.isSessionChecked = true
    }

    func signIn(email: String, password: String) async {
        print("[AuthViewModel] signIn: attempting email=\(email)")
        isLoading = true
        errorMessage = nil
        do {
            let response = try await supabase.auth.signIn(email: email, password: password)
            self.currentUser = response.user
            print("[AuthViewModel] signIn: auth OK userId=\(response.user.id)")
            await fetchProfile()
            self.isAuthenticated = true
            print("[AuthViewModel] signIn: complete, role=\(self.resolvedRoleName ?? "nil")")
        } catch {
            print("[AuthViewModel] signIn ERROR: \(error)")
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signUp(email: String, password: String, fullName: String, role: String) async {
        isLoading = true
        errorMessage = nil
        do {
            // Map display role name to database role string
            let dbRole: String
            switch role.lowercased() {
            case "fleet manager": dbRole = "fleet_manager"
            case "driver": dbRole = "driver"
            case "maintenance": dbRole = "maintenance"
            default: dbRole = "fleet_manager"
            }
            
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: [
                    "fullName": .string(fullName),
                    "role": .string(dbRole)
                ]
            )
            self.currentUser = response.user
            await fetchProfile()
            self.isAuthenticated = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() async {
        do {
            try await supabase.auth.signOut()
            self.isAuthenticated = false
            self.currentUser = nil
            self.currentProfile = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
