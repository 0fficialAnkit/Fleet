import Foundation
import Supabase
import SwiftUI
import Observation

@MainActor
@Observable
class AuthViewModel {
    var isAuthenticated = false
    var currentUser: Auth.User?
    var errorMessage: String?
    var isLoading = false
    var isSessionChecked = false
    var resolvedRoleName: String?
    
    struct UserRecord: Codable {
        let role_id: UUID?
    }
    
    struct RoleRecord: Codable {
        let role_name: String?
    }
    
    func fetchRoleName() async {
        guard let userId = currentUser?.id else { return }
        do {
            let userRecord: UserRecord = try await supabase
                .from("users")
                .select("role_id")
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            guard let roleId = userRecord.role_id else { return }
            
            let roleRecord: RoleRecord = try await supabase
                .from("roles")
                .select("role_name")
                .eq("id", value: roleId)
                .single()
                .execute()
                .value
            
            self.resolvedRoleName = roleRecord.role_name
        } catch {
            print("Failed to fetch role name: \(error)")
            self.errorMessage = "Failed to load user role."
        }
    }
    
    func checkUserSession() async {
        do {
            let session = try await supabase.auth.session
            self.currentUser = session.user
            await fetchRoleName()
            self.isAuthenticated = true
        } catch {
            self.isAuthenticated = false
            self.currentUser = nil
            self.resolvedRoleName = nil
        }
        self.isSessionChecked = true
    }
    
    // Allows users to sign up with a specific role
    func signUp(email: String, password: String, fullName: String, role: String) async {
        isLoading = true
        errorMessage = nil
        do {
            // Map the human-readable UI role to the expected backend database UUID
            let roleId = switch role.lowercased() {
            case "driver": "41d7aa4d-5ad4-4fda-82da-992b8ac14657"
            case "maintenance": "7cb95205-1a35-4ffb-889a-3f8067f43cb9"
            default: "cb66109f-e887-4586-baed-2761a9029c61" // fleet_manager
            }
            
            let metadata: [String: AnyJSON] = [
                "fullName": .string(fullName),
                "role_id": .string(roleId)
            ]
            
            try await supabase.auth.signUp(
                email: email,
                password: password,
                data: metadata
            )
            
            // Ensure the user is not automatically logged in after creation
            try? await supabase.auth.signOut()
            self.isAuthenticated = false
            self.currentUser = nil
            self.resolvedRoleName = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await supabase.auth.signIn(email: email, password: password)
            self.currentUser = response.user
            await fetchRoleName()
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
            self.resolvedRoleName = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
