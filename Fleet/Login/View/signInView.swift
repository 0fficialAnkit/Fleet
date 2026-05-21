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
            Color.black
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
            Text("PrimeFleet")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)
            Text("Sign in to PrimeFleet")
            .font(.system(size: 16))
            .foregroundColor(.white.opacity(0.5))
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
    // MARK: - Main Button
    var actionButton: some View {
        Button {
            Task {
                await authViewModel.signIn(email: emailOrPhone, password: password)
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
                Text("Sign In")
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

}
// MARK: - Preview
#Preview {
    NavigationStack {
        SignInView()
            .environment(AuthViewModel())
    }
}
