import SwiftUI

struct CreateAccountView: View {
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var selectedRoleId: Int = 1
    @State private var isPasswordVisible = false

    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss

    let roleItems: [RoleDisplayItem] = [
        RoleDisplayItem(id: 1, roleName: "Fleet Manager", description: "", iconName: "shield.fill", iconColor: .blue, iconBackground: .clear),
        RoleDisplayItem(id: 2, roleName: "Driver", description: "", iconName: "box.truck.fill", iconColor: .blue, iconBackground: .clear),
        RoleDisplayItem(id: 3, roleName: "Maintenance", description: "", iconName: "wrench.and.screwdriver.fill", iconColor: .blue, iconBackground: .clear)
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
                        .foregroundColor(.primary)
                    
                    Text("Join FleetOps today")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)

                    Spacer().frame(height: 32)

                    Text("SELECT YOUR ROLE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .kerning(1.2)
                    
                    Spacer().frame(height: 16)

                    HStack(spacing: 12) {
                        ForEach(roleItems) { item in
                            RoleSelectionButton(
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

                    VStack(spacing: 20) {
                        // Full Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("FULL NAME")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "person")
                                    .foregroundColor(.secondary)
                                TextField("John Doe", text: $fullName)
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }

                        // Email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("EMAIL ADDRESS")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundColor(.secondary)
                                TextField("name@fleetops.com", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }

                        // Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PASSWORD")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                                
                            HStack {
                                Image(systemName: "lock")
                                    .foregroundColor(.secondary)
                                if isPasswordVisible {
                                    TextField("••••••••", text: $password)
                                        .foregroundColor(.primary)
                                } else {
                                    SecureField("••••••••", text: $password)
                                        .foregroundColor(.primary)
                                }
                                Button(action: { isPasswordVisible.toggle() }) {
                                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }

                        Spacer().frame(height: 4)

                        // Sign Up Button
                        Button(action: {
                            Task {
                                let selectedRoleName = roleItems.first(where: { $0.id == selectedRoleId })?.roleName ?? "Fleet Manager"
                                await authViewModel.signUp(email: email, password: password, fullName: fullName, role: selectedRoleName)
                                if authViewModel.errorMessage == nil {
                                    dismiss()
                                }
                            }
                        }) {
                            HStack {
                                if authViewModel.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Create Account")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.blue)
                            .cornerRadius(12)
                            .shadow(color: Color.blue.opacity(0.3), radius: 10, y: 5)
                        }
                        .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty || fullName.isEmpty)
                    }
                    .padding(24)
                    .background(Color(.systemBackground))
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.05), radius: 20, y: 10)

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationTitle("")
    }
}
