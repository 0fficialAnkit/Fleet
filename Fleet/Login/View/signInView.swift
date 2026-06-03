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
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.teal)
                .frame(width: 80, height: 80)
            Image(systemName: "truck.box.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color(.systemBackground))
        }
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
                Text(errorMessage)
                    .foregroundStyle(Color.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            
            if authViewModel.isWaitingForOTP {
                TextField(
                    "",
                    text: $otpCode,
                    prompt: Text("Enter 6-digit OTP")
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
            } else {
                TextField(
                    "",
                    text: $emailOrPhone,
                    prompt: Text("Enter email or phone")
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
                if roleId != 1 {
                    HStack {
                        Spacer()
                        Button {
                            showingResetPassword = true
                        } label: {
                            Text("Forgot Password?")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.teal)
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
    }
    // MARK: - Main Button
    var actionButton: some View {
        let isButtonDisabled = authViewModel.isWaitingForOTP ? otpCode.isEmpty : (emailOrPhone.isEmpty || password.isEmpty)
        return Button {
            Task {
                if authViewModel.isWaitingForOTP {
                    await authViewModel.verifyOTP(token: otpCode)
                } else {
                    await authViewModel.signIn(email: emailOrPhone, password: password)
                }
            }
        } label: {
            if authViewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: isButtonDisabled ? Color(.tertiaryLabel) : Color(.systemBackground)))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(isButtonDisabled ? Color(.tertiarySystemFill) : Color.teal)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                Text(authViewModel.isWaitingForOTP ? "Verify OTP & Sign In" : "Sign In")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isButtonDisabled ? Color(.tertiaryLabel) : Color(.systemBackground))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(isButtonDisabled ? Color(.tertiarySystemFill) : Color.teal)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .disabled(authViewModel.isLoading || isButtonDisabled)
        .sheet(isPresented: $showingResetPassword) {
            ResetPasswordView(email: emailOrPhone)
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