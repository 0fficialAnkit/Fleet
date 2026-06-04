import SwiftUI

struct OTPTextField: View {
    @Binding var text: String
    var themeColor: Color = .teal
    @FocusState private var isFocused: Bool
    @State private var isCursorVisible = false
    
    var body: some View {
        ZStack {
            TextField("", text: $text)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .foregroundStyle(.clear)
                .tint(.clear)
            
            HStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { index in
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isFocused ? themeColor : Color(.separator), lineWidth: isFocused ? 2 : 1)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        if index < text.count {
                            let charIndex = text.index(text.startIndex, offsetBy: index)
                            Text(String(text[charIndex]))
                                .font(.title2.bold())
                                .foregroundStyle(Color.primary)
                        } else if isFocused && index == text.count {
                            Rectangle()
                                .fill(themeColor)
                                .frame(width: 2, height: 24)
                                .opacity(isCursorVisible ? 1 : 0)
                                .onAppear {
                                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                                        isCursorVisible = true
                                    }
                                }
                        }
                    }
                    .frame(height: 56)
                }
            }
            .allowsHitTesting(false) // Let all taps pass through to the invisible TextField beneath
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }
}

struct ResetPasswordView: View {
    enum Step {
        case email
        case otp
        case newPassword
        case success
    }
    
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var authViewModel
    
    @State private var email: String = ""
    @State private var otpCode: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isPasswordVisible: Bool = false
    
    @State private var currentStep: Step = .email
    
    private var roleId: Int

    init(email: String = "", roleId: Int = 1) {
        self._email = State(initialValue: email)
        self.roleId = roleId
    }
    
    private var themeColor: Color {
        switch roleId {
        case 1: return .teal
        case 2: return .green
        case 3: return .brown
        default: return .teal
        }
    }
    
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
                                .fill(themeColor.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Image(systemName: "lock.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(themeColor)
                        }
                        .padding(.top, 32)
                        
                        // Text description
                        VStack(spacing: 8) {
                            Text("Reset Password")
                                .font(.title2.bold())
                                .foregroundStyle(.primary)
                            
                            Text(subtitleForStep)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                        
                        if currentStep == .success {
                            // Success message
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.green)
                                Text("Success!")
                                    .font(.headline)
                                Text("Your password has been successfully reset. You can now log in.")
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
                                
                                if currentStep == .email {
                                    emailField
                                } else if currentStep == .otp {
                                    OTPTextField(text: $otpCode, themeColor: themeColor)
                                        .onChange(of: otpCode) { _, newValue in
                                            if newValue.count > 6 {
                                                otpCode = String(newValue.prefix(6))
                                            }
                                        }
                                } else if currentStep == .newPassword {
                                    passwordFields
                                }
                                
                                Button(action: handleAction) {
                                    if authViewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 56)
                                            .background(isButtonDisabled ? Color(.tertiarySystemFill) : themeColor)
                                            .cornerRadius(14)
                                    } else {
                                        Text(buttonText)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(isButtonDisabled ? Color(.tertiaryLabel) : .white)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 56)
                                            .background(isButtonDisabled ? Color(.tertiarySystemFill) : themeColor)
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
    
    // MARK: - Fields
    private var emailField: some View {
        HStack {
            Image(systemName: "envelope")
                .foregroundStyle(Color(.placeholderText))
            TextField("", text: $email, prompt: Text("Email Address").foregroundStyle(Color(.placeholderText)))
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
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
    
    private var passwordFields: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lock")
                    .foregroundStyle(Color(.placeholderText))
                if isPasswordVisible {
                    TextField("", text: $newPassword, prompt: Text("New Password").foregroundStyle(Color(.placeholderText)))
                } else {
                    SecureField("", text: $newPassword, prompt: Text("New Password").foregroundStyle(Color(.placeholderText)))
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
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(.separator), lineWidth: 1)
            )
            
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundStyle(Color(.placeholderText))
                if isPasswordVisible {
                    TextField("", text: $confirmPassword, prompt: Text("Confirm Password").foregroundStyle(Color(.placeholderText)))
                } else {
                    SecureField("", text: $confirmPassword, prompt: Text("Confirm Password").foregroundStyle(Color(.placeholderText)))
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
            
            if !newPassword.isEmpty && !confirmPassword.isEmpty && newPassword != confirmPassword {
                Text("Passwords do not match")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 8)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var subtitleForStep: String {
        switch currentStep {
        case .email: return "Enter your email address to receive a 6-digit OTP."
        case .otp: return "Enter the 6-digit OTP sent to \(email)."
        case .newPassword: return "Enter your new password."
        case .success: return ""
        }
    }
    
    private var buttonText: String {
        switch currentStep {
        case .email: return "Verify through OTP"
        case .otp: return "Confirm OTP"
        case .newPassword: return "Update Password"
        case .success: return "Done"
        }
    }
    
    private var isButtonDisabled: Bool {
        switch currentStep {
        case .email: return email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .otp: return otpCode.count < 6
        case .newPassword: return newPassword.isEmpty || confirmPassword.isEmpty || newPassword != confirmPassword
        case .success: return false
        }
    }
    
    // MARK: - Actions
    private func handleAction() {
        Task {
            switch currentStep {
            case .email:
                await authViewModel.resetPassword(email: email.trimmingCharacters(in: .whitespacesAndNewlines))
                if authViewModel.errorMessage == nil {
                    withAnimation { currentStep = .otp }
                }
            case .otp:
                let success = await authViewModel.verifyRecoveryOTP(email: email.trimmingCharacters(in: .whitespacesAndNewlines), token: otpCode)
                if success {
                    withAnimation { currentStep = .newPassword }
                }
            case .newPassword:
                await authViewModel.updatePassword(newPassword: newPassword)
                if authViewModel.errorMessage == nil {
                    withAnimation { currentStep = .success }
                }
            case .success:
                dismiss()
            }
        }
    }
}

#Preview {
    ResetPasswordView()
        .environment(AuthViewModel())
}
