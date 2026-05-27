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
        RoleDisplayItem(id: 1, roleName: "Fleet Manager", description: "Manage fleet, drivers & analytics", iconName: "shield.fill", iconColor: Color.teal, iconBackground: Color.teal.opacity(0.15)),
        RoleDisplayItem(id: 2, roleName: "Driver", description: "View routes, log trips & fuel", iconName: "truck.box.fill", iconColor: Color.green, iconBackground: Color.green.opacity(0.15)),
        RoleDisplayItem(id: 3, roleName: "Maintenance", description: "Schedule repairs & manage parts", iconName: "wrench.and.screwdriver.fill", iconColor: Color.brown, iconBackground: Color.brown.opacity(0.15))
    ]

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 20)

                    Text("Create Account")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.primary)

                    Text("Join GoFleet today")
                        .font(.system(size: 15))
                        .foregroundColor(Color.secondary)
                        .padding(.top, 4)

                    Spacer().frame(height: 32)

                    Text("SELECT YOUR ROLE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.secondary)
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
                        TextField("", text: $fullName, prompt: Text("Full Name").foregroundColor(Color(.placeholderText)))
                            .foregroundColor(Color.primary)
                            .padding(.horizontal, 18)
                            .frame(height: 56)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(.separator), lineWidth: 1)
                            )

                        // Email
                        TextField("", text: $email, prompt: Text("Email address").foregroundColor(Color(.placeholderText)))
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .foregroundColor(Color.primary)
                            .padding(.horizontal, 18)
                            .frame(height: 56)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(.separator), lineWidth: 1)
                            )

                        // Password
                        HStack {
                            if isPasswordVisible {
                                TextField("", text: $password, prompt: Text("Password").foregroundColor(Color(.placeholderText)))
                                    .foregroundColor(Color.primary)
                            } else {
                                SecureField("", text: $password, prompt: Text("Password").foregroundColor(Color(.placeholderText)))
                                    .foregroundColor(Color.primary)
                            }
                            Button(action: { isPasswordVisible.toggle() }) {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundColor(Color.secondary)
                            }
                        }
                        .padding(.horizontal, 18)
                        .frame(height: 56)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(.separator), lineWidth: 1)
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
                                    ProgressView().tint(isButtonDisabled ? Color(.tertiaryLabel) : Color(.systemBackground))
                                } else {
                                    Text("Create Account")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                            }
                            .foregroundColor(isButtonDisabled ? Color(.tertiaryLabel) : Color(.systemBackground))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(isButtonDisabled ? Color(.tertiarySystemFill) : Color.teal)
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
                .foregroundColor(isSelected ? Color.teal : Color.secondary)

            Text(item.roleName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? Color.teal : Color.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(
            isSelected
            ? Color.teal.opacity(0.12)
            : Color(.systemBackground)
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.teal : Color(.opaqueSeparator), lineWidth: 1.5)
        )
    }
}