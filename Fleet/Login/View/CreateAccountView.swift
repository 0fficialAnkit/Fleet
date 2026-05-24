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
        RoleDisplayItem(id: 1, roleName: "Fleet Manager", description: "Manage fleet, drivers & analytics", iconName: "shield.fill", iconColor: .blue, iconBackground: Color.blue.opacity(0.25)),
        RoleDisplayItem(id: 2, roleName: "Driver", description: "View routes, log trips & fuel", iconName: "truck.box.fill", iconColor: Color(red: 0.2, green: 0.85, blue: 0.45), iconBackground: Color.green.opacity(0.2)),
        RoleDisplayItem(id: 3, roleName: "Maintenance", description: "Schedule repairs & manage parts", iconName: "wrench.and.screwdriver.fill", iconColor: .orange, iconBackground: Color.orange.opacity(0.2))
    ]

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.09, blue: 0.13)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 20)
                    
                    Text("Create Account")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Join FleetOS today")
                        .font(.system(size: 15))
                        .foregroundColor(Color.white.opacity(0.5))
                        .padding(.top, 4)

                    Spacer().frame(height: 32)

                    Text("SELECT YOUR ROLE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.5))
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
                        TextField("", text: $fullName, prompt: Text("Full Name").foregroundColor(.white.opacity(0.45)))
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .frame(height: 56)
                            .background(Color(red: 0.12, green: 0.14, blue: 0.18))
                            .cornerRadius(14)

                        // Email
                        TextField("", text: $email, prompt: Text("Email address").foregroundColor(.white.opacity(0.45)))
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .frame(height: 56)
                            .background(Color(red: 0.12, green: 0.14, blue: 0.18))
                            .cornerRadius(14)

                        // Password
                        HStack {
                            if isPasswordVisible {
                                TextField("", text: $password, prompt: Text("Password").foregroundColor(.white.opacity(0.45)))
                                    .foregroundColor(.white)
                            } else {
                                SecureField("", text: $password, prompt: Text("Password").foregroundColor(.white.opacity(0.45)))
                                    .foregroundColor(.white)
                            }
                            Button(action: { isPasswordVisible.toggle() }) {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .padding(.horizontal, 18)
                        .frame(height: 56)
                        .background(Color(red: 0.12, green: 0.14, blue: 0.18))
                        .cornerRadius(14)

                        Spacer().frame(height: 14)

                        // Sign Up Button
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
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Create Account")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.blue)
                            .cornerRadius(16)
                        }
                        .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty || fullName.isEmpty)
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
                .foregroundColor(isSelected ? .blue : .gray)
            
            Text(item.roleName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? .blue : .gray)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(
            isSelected 
            ? Color.blue.opacity(0.15) 
            : Color(red: 0.12, green: 0.14, blue: 0.18)
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color(red: 0.2, green: 0.22, blue: 0.28), lineWidth: 1.5)
        )
    }
}
