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
    
    // OTP & Predefined State
    var isWaitingForOTP = false
    var tempEmailForOTP: String?
    var pendingProfile: Profile?
    
    var currentUserEmail: String? {
        currentUser?.email ?? currentProfile?.email
    }

    /// Convenience: the logged-in user's UUID (same as currentUser?.id).
    /// All FleetManager ViewModels use this as their `adminId` to scope data.
    var currentUserId: UUID? {
        currentUser.map { UUID(uuidString: $0.id.uuidString) } ?? currentProfile?.id
    }

    /// Role name derived from the users + roles tables ("fleet_manager", "driver", "maintenance")
    var resolvedRoleName: String? {
        currentProfile?.role
    }

    // MARK: - Predefined Accounts for Bypassing Auth
    struct PredefinedAccount {
        let role: String
        let email: String
        let aliases: [String]
        let passwords: [String]
        let fullName: String
        let userId: UUID
        let phone: String?
        let licenseNumber: String?
        
        func toProfile() -> Profile {
            Profile(
                id: userId,
                fullName: fullName,
                email: email,
                phone: phone,
                licenseNumber: licenseNumber,
                role: role,
                status: "active",
                isOnDuty: true,
                createdAt: Date()
            )
        }
    }

    static let predefinedAccounts: [PredefinedAccount] = [
        PredefinedAccount(
            role: "fleet_manager",
            email: "manager@kafila.com",
            aliases: ["manager@fleet.com", "admin@fleet.com", "manager", "admin", "fleet_manager", "manager@kafila.in"],
            passwords: ["password123", "123456", "password", "admin123"],
            fullName: "Fleet Manager",
            userId: UUID(uuidString: "cb66109f-e887-4586-baed-2761a9029c61") ?? UUID(),
            phone: "+91 9876543210",
            licenseNumber: nil
        ),
        PredefinedAccount(
            role: "driver",
            email: "driver@kafila.com",
            aliases: ["driver@fleet.com", "driver", "ravi@fleet.in", "driver@kafila.in"],
            passwords: ["password123", "123456", "password", "driver123"],
            fullName: "Ravi Kumar",
            userId: UUID(uuidString: "41d7aa4d-5ad4-4fda-82da-992b8ac14657") ?? UUID(),
            phone: "+91 9876543211",
            licenseNumber: "DL-1420110012345"
        ),
        PredefinedAccount(
            role: "maintenance",
            email: "maintenance@kafila.com",
            aliases: ["maintenance@fleet.com", "maintenance", "maint@fleet.com", "mechanic", "maintenance@kafila.in"],
            passwords: ["password123", "123456", "password", "maint123"],
            fullName: "Suresh Sharma",
            userId: UUID(uuidString: "7cb95205-1a35-4ffb-889a-3f8067f43cb9") ?? UUID(),
            phone: "+91 9876543212",
            licenseNumber: nil
        )
    ]

    static let predefinedOTP = "123456"

    private let mockSessionKey = "kafila_mock_session_profile"

    private func saveMockSession(profile: Profile) {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: mockSessionKey)
        }
    }

    private func clearMockSession() {
        UserDefaults.standard.removeObject(forKey: mockSessionKey)
    }

    private func loadMockSession() -> Profile? {
        guard let data = UserDefaults.standard.data(forKey: mockSessionKey),
              let profile = try? JSONDecoder().decode(Profile.self, from: data) else {
            return nil
        }
        return profile
    }

    private func makeAuthUser(from profile: Profile) -> Auth.User {
        Auth.User(
            id: profile.id,
            appMetadata: [:],
            userMetadata: [
                "full_name": .string(profile.fullName),
                "role": .string(profile.role)
            ],
            aud: "authenticated",
            email: profile.email,
            createdAt: profile.createdAt ?? Date(),
            updatedAt: Date()
        )
    }

    func fetchProfile() async {
        if self.currentProfile != nil { return }
        if let sessionProfile = loadMockSession() {
            self.currentProfile = sessionProfile
            return
        }
        guard let user = currentUser else { return }
        print("[AuthViewModel] fetchProfile: offline mode active for \(user.id)")
    }

    func checkUserSession() async {
        print("[AuthViewModel] checkUserSession: checking offline mock session...")
        if let profile = loadMockSession() {
            let user = makeAuthUser(from: profile)
            self.currentUser = user
            self.currentProfile = profile
            self.isAuthenticated = true
            print("[AuthViewModel] checkUserSession: restored mock session for role=\(profile.role)")
        } else {
            self.isAuthenticated = false
            self.currentUser = nil
            self.currentProfile = nil
        }
        self.isSessionChecked = true
    }

    func signIn(email: String, password: String, expectedRole: String? = nil) async {
        print("[AuthViewModel] signIn: attempting email=\(email), expectedRole=\(expectedRole ?? "nil")")
        isLoading = true
        errorMessage = nil

        // Brief delay to give a realistic UI interaction feel
        try? await Task.sleep(nanoseconds: 200_000_000)

        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        // Find predefined account for expected role or by email
        let account: PredefinedAccount?
        if let expectedRole = expectedRole {
            account = Self.predefinedAccounts.first(where: { $0.role == expectedRole })
        } else {
            account = Self.predefinedAccounts.first(where: {
                $0.email.lowercased() == cleanedEmail ||
                $0.aliases.map { $0.lowercased() }.contains(cleanedEmail)
            }) ?? Self.predefinedAccounts.first
        }

        guard let targetAccount = account else {
            self.errorMessage = "No account found for this role."
            isLoading = false
            return
        }

        // Validate password (accept account passwords or common test passwords)
        let isDefaultValidPassword = cleanedPassword == "password123" || cleanedPassword == "123456" || cleanedPassword == "password"
        let isAccountPassword = targetAccount.passwords.contains(cleanedPassword)

        guard isDefaultValidPassword || isAccountPassword else {
            self.errorMessage = "Invalid password. Use predefined password: \(targetAccount.passwords.first ?? "password123")"
            isLoading = false
            return
        }

        // Build profile for 2FA OTP verification
        var profile = targetAccount.toProfile()
        if !cleanedEmail.isEmpty && cleanedEmail.contains("@") {
            profile.email = cleanedEmail
        }

        self.pendingProfile = profile
        self.tempEmailForOTP = profile.email
        self.isWaitingForOTP = true
        self.errorMessage = nil
        isLoading = false
        print("[AuthViewModel] signIn: credentials accepted, waiting for 2-factor OTP...")
    }

    func verifyOTP(token: String, expectedRole: String? = nil) async {
        guard let email = tempEmailForOTP ?? pendingProfile?.email else {
            self.errorMessage = "Session expired. Please sign in again."
            return
        }

        print("[AuthViewModel] verifyOTP: attempting for email=\(email)")
        isLoading = true
        errorMessage = nil

        try? await Task.sleep(nanoseconds: 200_000_000)

        let cleanedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)

        // Verify predefined OTP
        if cleanedToken == Self.predefinedOTP || cleanedToken == "000000" {
            let roleToUse = expectedRole ?? pendingProfile?.role ?? "fleet_manager"
            let profile = pendingProfile ?? Self.predefinedAccounts.first(where: { $0.role == roleToUse })?.toProfile() ?? Profile(
                id: UUID(),
                fullName: "User",
                email: email,
                role: roleToUse,
                status: "active",
                isOnDuty: true,
                createdAt: Date()
            )

            let user = makeAuthUser(from: profile)
            self.currentUser = user
            self.currentProfile = profile
            self.isAuthenticated = true
            self.isWaitingForOTP = false
            self.tempEmailForOTP = nil
            self.pendingProfile = nil
            self.errorMessage = nil
            saveMockSession(profile: profile)
            print("[AuthViewModel] verifyOTP: 2FA success! Logged in as role=\(profile.role)")
        } else {
            self.errorMessage = "Invalid OTP code. Please enter predefined OTP: \(Self.predefinedOTP)"
            print("[AuthViewModel] verifyOTP: Invalid OTP token entered.")
        }

        isLoading = false
    }

    func resetOTPState() {
        self.isWaitingForOTP = false
        self.tempEmailForOTP = nil
        self.pendingProfile = nil
        self.errorMessage = nil
    }

    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        try? await Task.sleep(nanoseconds: 200_000_000)
        isLoading = false
    }

    func verifyRecoveryOTP(email: String, token: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        try? await Task.sleep(nanoseconds: 200_000_000)
        isLoading = false
        let cleanedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanedToken == Self.predefinedOTP || cleanedToken == "000000" {
            return true
        } else {
            self.errorMessage = "Invalid OTP. Use predefined OTP: \(Self.predefinedOTP)"
            return false
        }
    }

    func updatePassword(newPassword: String) async {
        isLoading = true
        errorMessage = nil
        try? await Task.sleep(nanoseconds: 200_000_000)
        isLoading = false
    }

    func changePassword(email: String, oldPassword: String, newPassword: String) async {
        isLoading = true
        errorMessage = nil
        try? await Task.sleep(nanoseconds: 200_000_000)
        isLoading = false
    }

    func signUp(email: String, password: String, fullName: String, role: String) async {
        isLoading = true
        errorMessage = nil
        try? await Task.sleep(nanoseconds: 200_000_000)
        isLoading = false
    }

    func signOut() async {
        clearMockSession()
        self.isAuthenticated = false
        self.currentUser = nil
        self.currentProfile = nil
        self.isWaitingForOTP = false
        self.tempEmailForOTP = nil
        self.pendingProfile = nil
        self.errorMessage = nil
        print("[AuthViewModel] signOut: session cleared successfully")
    }

    func verifySessionStatus() async {
        // Offline bypass: local session remains valid until sign out
    }
}