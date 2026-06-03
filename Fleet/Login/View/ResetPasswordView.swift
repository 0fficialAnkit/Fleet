import SwiftUI

struct ResetPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var authViewModel
    
    @State var email: String = ""
    // No longer need old/new password fields
    
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
                            Text("Reset Password")
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                            
                            Text("Enter your email address to receive a password reset link.")
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
                                Text("A password reset link has been sent to your email address. Please check your inbox.")
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
                                
                                HStack {
                                    Image(systemName: "envelope")
                                        .foregroundColor(Color(.placeholderText))
                                    TextField("", text: $email, prompt: Text("Email Address").foregroundColor(Color(.placeholderText)))
                                        .keyboardType(.emailAddress)
                                        .textInputAutocapitalization(.never)
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
            .navigationTitle("Reset Password")
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
        return email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func handleSubmit() {
        Task {
            await authViewModel.resetPassword(email: email.trimmingCharacters(in: .whitespacesAndNewlines))
            
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
