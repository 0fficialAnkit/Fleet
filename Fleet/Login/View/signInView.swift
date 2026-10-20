//
//  SignInView.swift
//  Fleet
//
//  Created by Harshita Jiaswal on 19/05/26.
//

import SwiftUI

struct SignInView: View {

    // MARK: - Variables
    var roleId: Int = 1 // 1 = Fleet Manager, 2 = Driver, 3 = Maintenance
    
    @State private var emailOrPhone = ""
    @State private var password = ""
    @State private var otpCode = ""

    @State private var isPasswordVisible = false
    @State private var showingResetPassword = false

    @Environment(AuthViewModel.self) private var authViewModel

    // MARK: - Body
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 60)
                    appIcon
                    Spacer()
                        .frame(height: 20)
                    titleSection
                    Spacer()
                        .frame(height: 28)
                    inputFields

                    Spacer()
                        .frame(height: 28)
                    actionButton
                    Spacer()
                        .frame(height: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .onDisappear {
            authViewModel.resetOTPState()
        }
    }
    // MARK: - App Icon
    var appIcon: some View {
        AppLogoView(size: 120, cornerRadius: 26)
    }
    // MARK: - Title
    var titleSection: some View {
        VStack(spacing: 8) {
            Text("Kafila")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Color.primary)
            Text("Sign in to Kafila")
            .font(.system(size: 16))
            .foregroundStyle(Color.secondary)
        }
    }

    // MARK: - Input Fields
    var inputFields: some View {
        VStack(spacing: 14) {
            if let errorMessage = authViewModel.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                    Text(errorMessage)
                        .font(.caption)
                }
                .foregroundStyle(Color.red)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
            }
            
            if authViewModel.isWaitingForOTP {
                // Predefined OTP Quick Fill Card
                HStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(themeColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Two-Factor Authentication")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.primary)
                        Text("Predefined OTP: \(predefinedOTP)")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.secondary)
                    }
                    Spacer()
                    Button {
                        otpCode = predefinedOTP
                    } label: {
                        Text("Auto Fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(themeColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(themeColor.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(themeColor.opacity(0.25), lineWidth: 1)
                )

                TextField(
                    "",
                    text: $otpCode,
                    prompt: Text("Enter 6-digit OTP (e.g. \(predefinedOTP))")
                        .foregroundStyle(Color(.placeholderText))
                )
                .keyboardType(.numberPad)
                .textInputAutocapitalization(.never)
                .foregroundStyle(Color.primary)
                .padding(.horizontal, 18)
                .frame(height: 56)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(.separator), lineWidth: 1)
                )

                // Change Email / Back Button
                Button {
                    authViewModel.resetOTPState()
                    otpCode = ""
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Change email / password")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(themeColor)
                }
                .padding(.top, 4)

            } else {
                // Predefined Credentials Quick Fill Card
                HStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(themeColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Predefined Account")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.primary)
                        Text("\(predefinedEmail) • \(predefinedPassword)")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.secondary)
                    }
                    Spacer()
                    Button {
                        emailOrPhone = predefinedEmail
                        password = predefinedPassword
                    } label: {
                        Text("Auto Fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(themeColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(themeColor.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(themeColor.opacity(0.25), lineWidth: 1)
                )

                TextField(
                    "",
                    text: $emailOrPhone,
                    prompt: Text("Enter email")
                        .foregroundStyle(Color(.placeholderText))
                )
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .foregroundStyle(Color.primary)
                .padding(.horizontal, 18)
                .frame(height: 56)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(.separator), lineWidth: 1)
                )

                HStack {
                    if isPasswordVisible {
                        TextField(
                            "",
                            text: $password,
                            prompt: Text("Password")
                                .foregroundStyle(Color(.placeholderText))
                        )
                    } else {
                        SecureField(
                            "",
                            text: $password,
                            prompt: Text("Password")
                                .foregroundStyle(Color(.placeholderText))
                        )
                    }
                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .foregroundStyle(Color.secondary)
                    }
                }
                .foregroundStyle(Color.primary)
                .padding(.horizontal, 18)
                .frame(height: 56)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(.separator), lineWidth: 1)
                )
                
                // Forgot Password Link
                HStack {
                    Spacer()
                    Button {
                        showingResetPassword = true
                    } label: {
                        Text("Forgot Password?")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(themeColor)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
    // MARK: - Computed Properties
    var themeColor: Color {
        switch roleId {
        case 1: return .teal
        case 2: return .green
        case 3: return .brown
        default: return .teal
        }
    }
    
    var expectedRoleName: String {
        switch roleId {
        case 1: return "fleet_manager"
        case 2: return "driver"
        case 3: return "maintenance"
        default: return "fleet_manager"
        }
    }

    var predefinedEmail: String {
        switch roleId {
        case 1: return "manager@kafila.com"
        case 2: return "driver@kafila.com"
        case 3: return "maintenance@kafila.com"
        default: return "manager@kafila.com"
        }
    }

    var predefinedPassword: String {
        return "password123"
    }

    var predefinedOTP: String {
        return "123456"
    }

    // MARK: - Main Button
    var actionButton: some View {
        let isButtonDisabled = authViewModel.isWaitingForOTP ? otpCode.isEmpty : (emailOrPhone.isEmpty || password.isEmpty)
        return Button {
            Task {
                if authViewModel.isWaitingForOTP {
                    await authViewModel.verifyOTP(token: otpCode, expectedRole: expectedRoleName)
                } else {
                    await authViewModel.signIn(email: emailOrPhone, password: password, expectedRole: expectedRoleName)
                }
            }
        } label: {
            if authViewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: isButtonDisabled ? Color(.tertiaryLabel) : Color(.systemBackground)))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(isButtonDisabled ? Color(.tertiarySystemFill) : themeColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                Text(authViewModel.isWaitingForOTP ? "Verify OTP & Sign In" : "Sign In")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isButtonDisabled ? Color(.tertiaryLabel) : Color(.systemBackground))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(isButtonDisabled ? Color(.tertiarySystemFill) : themeColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .disabled(authViewModel.isLoading || isButtonDisabled)
        .sheet(isPresented: $showingResetPassword) {
            ResetPasswordView(email: emailOrPhone, roleId: roleId)
        }
    }

}
// MARK: - Preview
#Preview {
    NavigationStack {
        SignInView(roleId: 2)
            .environment(AuthViewModel())
    }
}