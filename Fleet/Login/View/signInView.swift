//
//  SignInView.swift
//  Fleet
//
//  Created by Harshita Jiaswal on 19/05/26.
//

import SwiftUI

struct SignInView: View {

    // MARK: - Variables
    @State private var emailOrPhone = ""
    @State private var password = ""

    @State private var isPasswordVisible = false

    @Environment(AuthViewModel.self) private var authViewModel


    // MARK: - Body
    var body: some View {
        ZStack {
            themeModel.backgroundPrimary
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
    }
    // MARK: - App Icon
    var appIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(themeModel.accent)
                .frame(width: 80, height: 80)
            Image(systemName: "truck.box.fill")
                .font(.system(size: 36))
                .foregroundColor(themeModel.accentForeground)
        }
    }
    // MARK: - Title
    var titleSection: some View {
        VStack(spacing: 8) {
            Text("GoFleet")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(themeModel.textPrimary)
            Text("Sign in to GoFleet")
            .font(.system(size: 16))
            .foregroundColor(themeModel.textSecondary)
        }
    }

    // MARK: - Input Fields
    var inputFields: some View {
        VStack(spacing: 14) {
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(themeModel.danger)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            TextField(
                "",
                text: $emailOrPhone,
                prompt: Text("Enter email or phone")
                    .foregroundColor(themeModel.placeholder)
            )
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .foregroundColor(themeModel.textPrimary)
                .padding(.horizontal, 18)
                .frame(height: 56)
                .background(themeModel.inputBackground)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(themeModel.divider, lineWidth: 1)
                )

            HStack {
                if isPasswordVisible {
                    TextField(
                        "",
                        text: $password,
                        prompt: Text("Password")
                            .foregroundColor(themeModel.placeholder)
                    )
                } else {
                    SecureField(
                        "",
                        text: $password,
                        prompt: Text("Password")
                            .foregroundColor(themeModel.placeholder)
                    )
                }
                Button {
                    isPasswordVisible.toggle()
                } label: {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .foregroundColor(themeModel.textSecondary)
                }
            }
            .foregroundColor(themeModel.textPrimary)
            .padding(.horizontal, 18)
            .frame(height: 56)
            .background(themeModel.inputBackground)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(themeModel.divider, lineWidth: 1)
            )
        }
    }
    // MARK: - Main Button
    var actionButton: some View {
        let isButtonDisabled = emailOrPhone.isEmpty || password.isEmpty
        return Button {
            Task {
                await authViewModel.signIn(email: emailOrPhone, password: password)
            }
        } label: {
            if authViewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: isButtonDisabled ? themeModel.buttonDisabledText : themeModel.accentForeground))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(isButtonDisabled ? themeModel.buttonDisabled : themeModel.accent)
                    .cornerRadius(16)
            } else {
                Text("Sign In")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isButtonDisabled ? themeModel.buttonDisabledText : themeModel.accentForeground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(isButtonDisabled ? themeModel.buttonDisabled : themeModel.accent)
                    .cornerRadius(16)
            }
        }
        .disabled(authViewModel.isLoading || isButtonDisabled)
    }

}
// MARK: - Preview
#Preview {
    NavigationStack {
        SignInView()
            .environment(AuthViewModel())
    }
}
