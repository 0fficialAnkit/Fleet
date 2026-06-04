import SwiftUI

struct ChangePasswordSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var authViewModel
    
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
                            Image(systemName: "key.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.teal)
                        }
                        .padding(.top, 32)
                        
                        // Text description
                        VStack(spacing: 8) {
                            Text("Change Password")
                                .font(.title2.bold())
                                .foregroundStyle(.primary)
                            
                            Text("Enter your old password and your new password to change it.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                        
                        if isSuccess {
                            // Success message
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.green)
                                Text("Success!")
                                    .font(.headline)
                                Text("Your password has been changed successfully. You will be signed out.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
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
                                        .foregroundStyle(Color.red)
                                        .font(.caption)
                                        .multilineTextAlignment(.center)
                                }
                                
                                if !newPassword.isEmpty && newPassword != confirmPassword {
                                    Text("New password and confirm password do not match.")
                                        .foregroundStyle(Color.red)
                                        .font(.caption)
                                        .multilineTextAlignment(.center)
                                }
                                
                                HStack {
                                    if isOldPasswordVisible {
                                        TextField("", text: $oldPassword, prompt: Text("Old Password").foregroundStyle(Color(.placeholderText)))
                                    } else {
                                        SecureField("", text: $oldPassword, prompt: Text("Old Password").foregroundStyle(Color(.placeholderText)))
                                    }
                                    Button { isOldPasswordVisible.toggle() } label: {
                                        Image(systemName: isOldPasswordVisible ? "eye.slash" : "eye").foregroundStyle(.secondary)
                                    }
                                }
                                .foregroundStyle(Color.primary)
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
                                        TextField("", text: $newPassword, prompt: Text("New Password").foregroundStyle(Color(.placeholderText)))
                                    } else {
                                        SecureField("", text: $newPassword, prompt: Text("New Password").foregroundStyle(Color(.placeholderText)))
                                    }
                                    Button { isNewPasswordVisible.toggle() } label: {
                                        Image(systemName: isNewPasswordVisible ? "eye.slash" : "eye").foregroundStyle(.secondary)
                                    }
                                }
                                .foregroundStyle(Color.primary)
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
                                        TextField("", text: $confirmPassword, prompt: Text("Confirm Password").foregroundStyle(Color(.placeholderText)))
                                    } else {
                                        SecureField("", text: $confirmPassword, prompt: Text("Confirm Password").foregroundStyle(Color(.placeholderText)))
                                    }
                                    Button { isConfirmPasswordVisible.toggle() } label: {
                                        Image(systemName: isConfirmPasswordVisible ? "eye.slash" : "eye").foregroundStyle(.secondary)
                                    }
                                }
                                .foregroundStyle(Color.primary)
                                .padding(.horizontal, 18)
                                .frame(height: 56)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color(.separator), lineWidth: 1)
                                )
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if authViewModel.isLoading {
                        ProgressView()
                    } else {
                        Button("Save") {
                            handleSubmit()
                        }
                        .font(.headline)
                        .disabled(authViewModel.isLoading || isButtonDisabled)
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
            // Need the current user's email to re-authenticate and change password securely
            guard let email = authViewModel.currentUserEmail else {
                return
            }
            
            await authViewModel.changePassword(email: email, oldPassword: oldPassword, newPassword: newPassword)
            
            if authViewModel.errorMessage == nil {
                withAnimation {
                    isSuccess = true
                }
                
                // Automatically dismiss after a moment since they will be logged out anyway
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    ChangePasswordSheetView()
        .environment(AuthViewModel())
}
