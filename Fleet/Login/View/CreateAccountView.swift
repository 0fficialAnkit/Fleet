import SwiftUI

struct CreateAccountView: View {
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var selectedRoleId: Int = 1
    @State private var isPasswordVisible = false
    
    var onSuccess: (() -> Void)? = nil

    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss

    let roleItems: [RoleDisplayItem] = [
        RoleDisplayItem(id: 1, roleName: "Fleet Manager", description: "Manage fleet, drivers & analytics", iconName: "shield.fill", iconColor: themeModel.accent, iconBackground: themeModel.accent.opacity(0.15)),
        RoleDisplayItem(id: 2, roleName: "Driver", description: "View routes, log trips & fuel", iconName: "truck.box.fill", iconColor: themeModel.driverPrimary, iconBackground: themeModel.driverPrimary.opacity(0.15)),
        RoleDisplayItem(id: 3, roleName: "Maintenance", description: "Schedule repairs & manage parts", iconName: "wrench.and.screwdriver.fill", iconColor: themeModel.maintenancePrimary, iconBackground: themeModel.maintenancePrimary.opacity(0.15))
    ]

    var body: some View {
        ZStack {
            themeModel.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 20)
                    
                    Text("Create Account")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(themeModel.textPrimary)
                    
                    Text("Join GoFleet today")
                        .font(.system(size: 15))
                        .foregroundColor(themeModel.textSecondary)
                        .padding(.top, 4)

                    Spacer().frame(height: 32)

                    Text("SELECT YOUR ROLE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(themeModel.textSecondary)
                        .kerning(1.2)
                    
                    Spacer().frame(height: 16)

                    // Role Card List (horizontal squares without descriptions)
                    HStack(spacing: 12) {
                        ForEach(roleItems) { item in
                            SquareRoleCardView(
                                item: item,
                                isSelected: selectedRoleId == item.id
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedRoleId = item.id
                                }
                            }
                        }
                    }

                    Spacer().frame(height: 32)

                    VStack(spacing: 14) {
                        // Full Name
                        TextField("", text: $fullName, prompt: Text("Full Name").foregroundColor(themeModel.placeholder))
                            .foregroundColor(themeModel.textPrimary)
                            .padding(.horizontal, 18)
                            .frame(height: 56)
                            .background(themeModel.inputBackground)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(themeModel.divider, lineWidth: 1)
                            )

                        // Email
                        TextField("", text: $email, prompt: Text("Email address").foregroundColor(themeModel.placeholder))
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

                        // Password
                        HStack {
                            if isPasswordVisible {
                                TextField("", text: $password, prompt: Text("Password").foregroundColor(themeModel.placeholder))
                                    .foregroundColor(themeModel.textPrimary)
                            } else {
                                SecureField("", text: $password, prompt: Text("Password").foregroundColor(themeModel.placeholder))
                                    .foregroundColor(themeModel.textPrimary)
                            }
                            Button(action: { isPasswordVisible.toggle() }) {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundColor(themeModel.textSecondary)
                            }
                        }
                        .padding(.horizontal, 18)
                        .frame(height: 56)
                        .background(themeModel.inputBackground)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(themeModel.divider, lineWidth: 1)
                        )

                        Spacer().frame(height: 14)

                        // Sign Up Button
                        let isButtonDisabled = email.isEmpty || password.isEmpty || fullName.isEmpty
                        Button(action: {
                            Task {
                                let selectedRoleName = roleItems.first(where: { $0.id == selectedRoleId })?.roleName ?? "Fleet Manager"
                                await authViewModel.signUp(email: email, password: password, fullName: fullName, role: selectedRoleName)
                                if authViewModel.errorMessage == nil {
                                    if let onSuccess = onSuccess {
                                        onSuccess()
                                    } else {
                                        dismiss()
                                    }
                                }
                            }
                        }) {
                            HStack {
                                if authViewModel.isLoading {
                                    ProgressView().tint(isButtonDisabled ? themeModel.buttonDisabledText : themeModel.accentForeground)
                                } else {
                                    Text("Create Account")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                            }
                            .foregroundColor(isButtonDisabled ? themeModel.buttonDisabledText : themeModel.accentForeground)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(isButtonDisabled ? themeModel.buttonDisabled : themeModel.accent)
                            .cornerRadius(16)
                        }
                        .disabled(authViewModel.isLoading || isButtonDisabled)
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationTitle("")
    }
}

// MARK: - SquareRoleCardView
struct SquareRoleCardView: View {
    let item: RoleDisplayItem
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: item.iconName)
                .font(.system(size: 20))
                .foregroundColor(isSelected ? themeModel.accent : themeModel.textSecondary)
            
            Text(item.roleName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? themeModel.accent : themeModel.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(
            isSelected 
            ? themeModel.accent.opacity(0.12) 
            : themeModel.backgroundElevated
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? themeModel.accent : themeModel.border, lineWidth: 1.5)
        )
    }
}
