import SwiftUI

struct ResetPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var authViewModel
    
    @State var email: String = ""
    @State private var oldPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    @State private var isOldPasswordVisible = false
    @State private var isNewPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    
    @State private var isSuccess = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header icon
                        ZStack {
                            Circle()
                                .fill(Color.teal.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Image(systemName: "lock.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.teal)
                        }
                        .padding(.top, 32)
                        
                        // Text description
                        VStack(spacing: 8) {
                            Text("Forgot Password")
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                            
                            Text("Enter your old password and your new password to reset it.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                        
                        if isSuccess {
                            // Success message
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.green)
                                Text("Success!")
                                    .font(.headline)
                                Text("Your password has been changed successfully. You can now log in.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(16)
                            
                        } else {
                            // Form
                            VStack(spacing: 16) {
                                if let errorMessage = authViewModel.errorMessage {
                                    Text(errorMessage)
                                        .foregroundColor(Color.red)
                                        .font(.caption)
                                        .multilineTextAlignment(.center)
                                }
                                
                                if !newPassword.isEmpty && newPassword != confirmPassword {
                                    Text("New password and confirm password do not match.")
                                        .foregroundColor(Color.red)
                                        .font(.caption)
                                        .multilineTextAlignment(.center)
                                }
                                
                                HStack {
                                    if isOldPasswordVisible {
                                        TextField("", text: $oldPassword, prompt: Text("Old Password").foregroundColor(Color(.placeholderText)))
                                    } else {
                                        SecureField("", text: $oldPassword, prompt: Text("Old Password").foregroundColor(Color(.placeholderText)))
                                    }
                                    Button { isOldPasswordVisible.toggle() } label: {
                                        Image(systemName: isOldPasswordVisible ? "eye.slash" : "eye").foregroundColor(.secondary)
                                    }
                                }
                                .foregroundColor(Color.primary)
                                .padding(.horizontal, 18)
                                .frame(height: 56)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color(.separator), lineWidth: 1)
                                )
                                
                                HStack {
                                    if isNewPasswordVisible {
                                        TextField("", text: $newPassword, prompt: Text("New Password").foregroundColor(Color(.placeholderText)))
                                    } else {
                                        SecureField("", text: $newPassword, prompt: Text("New Password").foregroundColor(Color(.placeholderText)))
                                    }
                                    Button { isNewPasswordVisible.toggle() } label: {
                                        Image(systemName: isNewPasswordVisible ? "eye.slash" : "eye").foregroundColor(.secondary)
                                    }
                                }
                                .foregroundColor(Color.primary)
                                .padding(.horizontal, 18)
                                .frame(height: 56)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color(.separator), lineWidth: 1)
                                )
                                
                                HStack {
                                    if isConfirmPasswordVisible {
                                        TextField("", text: $confirmPassword, prompt: Text("Confirm Password").foregroundColor(Color(.placeholderText)))
                                    } else {
                                        SecureField("", text: $confirmPassword, prompt: Text("Confirm Password").foregroundColor(Color(.placeholderText)))
                                    }
                                    Button { isConfirmPasswordVisible.toggle() } label: {
                                        Image(systemName: isConfirmPasswordVisible ? "eye.slash" : "eye").foregroundColor(.secondary)
                                    }
                                }
                                .foregroundColor(Color.primary)
                                .padding(.horizontal, 18)
                                .frame(height: 56)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color(.separator), lineWidth: 1)
                                )
                                
                                Button(action: handleSubmit) {
                                    if authViewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 56)
                                            .background(isButtonDisabled ? Color(.tertiarySystemFill) : Color.teal)
                                            .cornerRadius(14)
                                    } else {
                                        Text("Reset Password")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(isButtonDisabled ? Color(.tertiaryLabel) : .white)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 56)
                                            .background(isButtonDisabled ? Color(.tertiarySystemFill) : Color.teal)
                                            .cornerRadius(14)
                                    }
                                }
                                .disabled(authViewModel.isLoading || isButtonDisabled)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationTitle("Forgot Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isButtonDisabled: Bool {
        if oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty { return true }
        if newPassword != confirmPassword { return true }
        return false
    }
    
    private func handleSubmit() {
        Task {
            await authViewModel.changePassword(email: email, oldPassword: oldPassword, newPassword: newPassword)
            
            if authViewModel.errorMessage == nil {
                withAnimation {
                    isSuccess = true
                }
            }
        }
    }
}

#Preview {
    ResetPasswordView()
        .environment(AuthViewModel())
}
