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
    
    // OTP Variables
    var isWaitingForOTP = false
    var tempEmailForOTP: String?
    
    var currentUserEmail: String? {
        currentUser?.email
    }

    /// Convenience: the logged-in user's UUID (same as currentUser?.id).
    /// All FleetManager ViewModels use this as their `adminId` to scope data.
    var currentUserId: UUID? {
        currentUser.map { UUID(uuidString: $0.id.uuidString) } ?? nil
    }

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
            if self.currentProfile != nil {
                self.isAuthenticated = true
                print("[AuthViewModel] checkUserSession: authenticated, role=\(self.resolvedRoleName ?? "nil")")
            } else {
                try? await supabase.auth.signOut()
                self.isAuthenticated = false
                self.currentUser = nil
                self.errorMessage = nil
            }
        } catch {
            print("[AuthViewModel] checkUserSession: no active session — \(error)")
            self.isAuthenticated = false
            self.currentUser = nil
            self.currentProfile = nil
            self.errorMessage = nil
        }
        self.isSessionChecked = true
    }

    func signIn(email: String, password: String) async {
        print("[AuthViewModel] signIn: attempting email=\(email)")
        isLoading = true
        errorMessage = nil
        do {
            // 1. Verify Password First
            let response = try await supabase.auth.signIn(email: email, password: password)
            
            // 2. Send OTP
            try await supabase.auth.signInWithOTP(email: email)
            
            // 3. Update state to show OTP screen
            self.tempEmailForOTP = email
            self.isWaitingForOTP = true
            
            // Note: We don't set isAuthenticated = true here because they still need to verify the OTP.
            // Sign out the temporary session created by signIn so they are fully required to enter OTP.
            try? await supabase.auth.signOut()
            
        } catch {
            print("[AuthViewModel] signIn ERROR: \(error)")
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func verifyOTP(token: String) async {
        guard let email = tempEmailForOTP else { return }
        
        print("[AuthViewModel] verifyOTP: attempting for email=\(email)")
        isLoading = true
        errorMessage = nil
        do {
            // Verify the OTP
            let response = try await supabase.auth.verifyOTP(
                email: email,
                token: token,
                type: .email // Use .magiclink if .email gives an issue, but .email is standard for 6-digit OTP
            )
            
            self.currentUser = response.user
            print("[AuthViewModel] verifyOTP: auth OK userId=\(response.user.id)")
            await fetchProfile()
            
            if self.currentProfile != nil {
                self.isAuthenticated = true
                self.isWaitingForOTP = false // Reset state
                print("[AuthViewModel] verifyOTP: complete, role=\(self.resolvedRoleName ?? "nil")")
            } else {
                try? await supabase.auth.signOut()
                self.isAuthenticated = false
                self.currentUser = nil
                self.errorMessage = "Profile not found."
            }
        } catch {
            print("[AuthViewModel] verifyOTP ERROR: \(error)")
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func resetOTPState() {
        self.isWaitingForOTP = false
        self.tempEmailForOTP = nil
        self.errorMessage = nil
    }
    
    func resetPassword(email: String) async {
        print("[AuthViewModel] resetPassword: attempting email=\(email)")
        isLoading = true
        errorMessage = nil
        do {
            try await supabase.auth.resetPasswordForEmail(email)
            print("[AuthViewModel] resetPassword: reset email sent successfully")
        } catch {
            print("[AuthViewModel] resetPassword ERROR: \(error)")
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func updatePassword(newPassword: String) async {
        print("[AuthViewModel] updatePassword: attempting to change password")
        isLoading = true
        errorMessage = nil
        do {
            try await supabase.auth.update(user: UserAttributes(password: newPassword))
            print("[AuthViewModel] updatePassword: password changed successfully")
        } catch {
            print("[AuthViewModel] updatePassword ERROR: \(error)")
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func changePassword(email: String, oldPassword: String, newPassword: String) async {
        print("[AuthViewModel] changePassword: attempting for email=\(email)")
        isLoading = true
        errorMessage = nil
        do {
            // Temporarily sign in
            let response = try await supabase.auth.signIn(email: email, password: oldPassword)
            // Update password
            try await supabase.auth.update(user: UserAttributes(password: newPassword))
            // Sign out to force them to log in with new password
            try await supabase.auth.signOut()
            print("[AuthViewModel] changePassword: password changed and signed out successfully")
        } catch {
            print("[AuthViewModel] changePassword ERROR: \(error)")
            self.errorMessage = error.localizedDescription
            // In case signIn succeeded but update failed, try to sign out
            try? await supabase.auth.signOut()
        }
        isLoading = false
    }

    func signUp(email: String, password: String, fullName: String, role: String) async {
        isLoading = true
        errorMessage = nil
        do {
            // Map display role name to database role string and exact UUID from Supabase
            let dbRole: String
            let roleIdStr: String
            switch role.lowercased() {
            case "fleet manager":
                dbRole = "fleet_manager"
                roleIdStr = "cb66109f-e887-4586-baed-2761a9029c61"
            case "driver":
                dbRole = "driver"
                roleIdStr = "41d7aa4d-5ad4-4fda-82da-992b8ac14657"
            case "maintenance":
                dbRole = "maintenance"
                roleIdStr = "7cb95205-1a35-4ffb-889a-3f8067f43cb9"
            default:
                dbRole = "fleet_manager"
                roleIdStr = "cb66109f-e887-4586-baed-2761a9029c61"
            }

            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: [
                    "fullName": .string(fullName),
                    "role": .string(dbRole),
                    "role_id": .string(roleIdStr)
                ]
            )

            // Explicitly insert into the public.users table just in case there is no database trigger
            let user = response.user
            if let roleUUID = UUID(uuidString: roleIdStr) {
                struct UserInsert: Codable {
                    let id: UUID
                    let full_name: String
                    let email: String
                    let role_id: UUID
                    let status: String
                }
                let newUser = UserInsert(id: user.id, full_name: fullName, email: email, role_id: roleUUID, status: "active")
                do {
                    try await supabase.from("users").insert(newUser).execute()
                    print("[AuthViewModel] Successfully inserted new user into public.users table.")
                } catch {
                    print("[AuthViewModel] Insert into users table failed (a trigger might have already done it): \(error)")
                }
            }

            // Ensure we don't automatically log in after sign up
            try? await supabase.auth.signOut()
            self.isAuthenticated = false
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() async {
        do {
            try await supabase.auth.signOut()
        } catch {
            print("[AuthViewModel] signOut ERROR: \(error)")
        }
        // Always clear local state to prevent getting stuck
        self.isAuthenticated = false
        self.currentUser = nil
        self.currentProfile = nil
        self.errorMessage = nil
    }

    /// Proactively verify that the logged-in user still exists in the Supabase database.
    /// If not (e.g. auth deleted in backend), we force an immediate logout.
    func verifySessionStatus() async {
        guard isAuthenticated, let user = currentUser else { return }
        do {
            let _: User = try await supabase
                .from("users")
                .select()
                .eq("id", value: user.id)
                .single()
                .execute()
                .value
            print("[AuthViewModel] verifySessionStatus: Session is valid and active.")
        } catch {
            print("[AuthViewModel] verifySessionStatus: User profile deleted or invalid JWT. Logging out...")
            await signOut()
        }
    }
}