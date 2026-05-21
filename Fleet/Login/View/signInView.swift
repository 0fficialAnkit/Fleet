//
//  SignInView.swift
//  Fleet
//
//  Created by Harshita Jiaswal on 19/05/26.
//

import SwiftUI

struct SignInView: View {

    // MARK: - Variables
    @State var selectedTab: AuthTab

    var showSignUp: Bool = true

    @State private var fullName = ""
    @State private var emailOrPhone = ""
    @State private var password = ""

    @State private var isPasswordVisible = false

    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var authViewModel

    // MARK: - Tabs
    enum AuthTab {
        case signIn
        case signUp
    }
    // MARK: - Body
    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.09, blue: 0.13)
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 60)
                    appIcon
                    Spacer()
                        .frame(height: 20)
                    titleSection
                    if showSignUp {
                        Spacer()
                            .frame(height: 36)
                        tabToggle
                    }
                    Spacer()
                        .frame(height: 28)
                    inputFields
                    
                    if selectedTab == .signIn {
                        Spacer()
                            .frame(height: 16)
                        faceIDButton
                    }
                    Spacer()
                        .frame(height: 28)
                    actionButton
                    Spacer()
                        .frame(height: 24)
                    backButton
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
                .fill(Color.blue)
                .frame(width: 80, height: 80)
            Image(systemName: "truck.box.fill")
                .font(.system(size: 36))
                .foregroundColor(.white)
        }
    }
    // MARK: - Title
    var titleSection: some View {
        VStack(spacing: 8) {
            Text("FleetOS")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)
            Text(
                selectedTab == .signIn
                ? "Sign in to FleetOS"
                : "Sign up to FleetOS"
            )
            .font(.system(size: 16))
            .foregroundColor(.white.opacity(0.5))
        }
    }

    // MARK: - Toggle
    var tabToggle: some View {
        HStack(spacing: 0) {
            tabButton(title: "Sign In", tab: .signIn)
            tabButton(title: "Sign Up", tab: .signUp)
        }
        .background(Color(red: 0.12, green: 0.14, blue: 0.18))
        .cornerRadius(14)
    }

    func tabButton(title: String, tab: AuthTab) -> some View {
        Button {
            withAnimation {
                selectedTab = tab
                fullName = ""
                emailOrPhone = ""
                password = ""
            }
        } label: {
            Text(title)
                .font(
                    .system(
                        size: 16,
                        weight: selectedTab == tab ? .bold : .regular
                    )
                )
                .foregroundColor(
                    selectedTab == tab
                    ? .white
                    : .white.opacity(0.45)
                )
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    selectedTab == tab
                    ? Color(red: 0.2, green: 0.22, blue: 0.28)
                    : Color.clear
                )
                .cornerRadius(12)
                .padding(4)
        }
    }

    // MARK: - Input Fields
    var inputFields: some View {
        VStack(spacing: 14) {
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            if selectedTab == .signUp {
                TextField(
                    "",
                    text: $fullName,
                    prompt: Text("Full Name")
                        .foregroundColor(.white.opacity(0.45))
                )
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .frame(height: 56)
                    .background(Color(red: 0.12, green: 0.14, blue: 0.18))
                    .cornerRadius(14)
            }
            TextField(
                "",
                text: $emailOrPhone,
                prompt: Text("Enter email or phone")
                    .foregroundColor(.white.opacity(0.45))
            )
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .frame(height: 56)
                .background(Color(red: 0.12, green: 0.14, blue: 0.18))
                .cornerRadius(14)

            HStack {
                if isPasswordVisible {
                    TextField(
                        "",
                        text: $password,
                        prompt: Text("Password")
                            .foregroundColor(.white.opacity(0.45))
                    )
                } else {
                    SecureField(
                        "",
                        text: $password,
                        prompt: Text("Password")
                            .foregroundColor(.white.opacity(0.45))
                    )
                }
                Button {
                    isPasswordVisible.toggle()
                } label: {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .frame(height: 56)
            .background(Color(red: 0.12, green: 0.14, blue: 0.18))
            .cornerRadius(14)
        }
    }
    // MARK: - Face ID
    var faceIDButton: some View {
        Button {
            print("Face ID tapped")
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "faceid")
                    .font(.system(size: 22))
                Text("Sign in with Face ID")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.blue.opacity(0.12))
            .cornerRadius(14)
        }
    }

    // MARK: - Main Button
    var actionButton: some View {
        Button {
            Task {
                if selectedTab == .signIn {
                    await authViewModel.signIn(email: emailOrPhone, password: password)
                } else {
                    await authViewModel.signUp(email: emailOrPhone, password: password, fullName: fullName)
                }
            }
        } label: {
            if authViewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.blue)
                    .cornerRadius(16)
            } else {
                Text(selectedTab == .signIn ? "Sign In" : "Create Account")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.blue)
                    .cornerRadius(16)
            }
        }
        .disabled(authViewModel.isLoading || emailOrPhone.isEmpty || password.isEmpty)
    }
    // MARK: - Back Button
    var backButton: some View {
        Button {
            dismiss()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.left")
                Text("Back to role selection")
            }
            .foregroundColor(.white.opacity(0.45))
        }
    }
}
// MARK: - Preview
#Preview {
    NavigationStack {
        SignInView(
            selectedTab: .signIn,
            showSignUp: true
        )
    }
}
