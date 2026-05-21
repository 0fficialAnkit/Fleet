import SwiftUI

// MARK: - RoleDisplayItem
struct RoleDisplayItem: Identifiable {
    let id: Int
    let roleName: String
    let description: String
    let iconName: String
    let iconColor: Color
    let iconBackground: Color
}

// MARK: - LoginView
struct LoginView: View {
    @State private var selectedRoleId: Int = 1
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var navigateToCreateAccount = false

    @Environment(AuthViewModel.self) private var authViewModel

    let roleItems: [RoleDisplayItem] = [
        RoleDisplayItem(id: 1, roleName: "Fleet Manager", description: "", iconName: "shield.fill", iconColor: .blue, iconBackground: .clear),
        RoleDisplayItem(id: 2, roleName: "Driver", description: "", iconName: "box.truck.fill", iconColor: .blue, iconBackground: .clear),
        RoleDisplayItem(id: 3, roleName: "Maintenance", description: "", iconName: "wrench.and.screwdriver.fill", iconColor: .blue, iconBackground: .clear)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.98, green: 0.98, blue: 0.99)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 20)
                        
                        // App Icon Button
                        Button(action: {
                            navigateToCreateAccount = true
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color(red: 0.05, green: 0.2, blue: 0.6))
                                    .frame(width: 64, height: 64)
                                    .shadow(color: Color.blue.opacity(0.2), radius: 10, y: 5)
                                Image(systemName: "box.truck.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        Spacer().frame(height: 16)

                        // Title
                        Text("FleetOps")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.15))
                        
                        Text("Precision logistics at your fingertips.")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                            .padding(.top, 4)

                        Spacer().frame(height: 32)

                        Text("SELECT YOUR ROLE")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.gray)
                            .kerning(1.2)
                        
                        Spacer().frame(height: 16)

                        // Role Selection Row
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

                        // Form Card
                        VStack(spacing: 20) {
                            // Email
                            VStack(alignment: .leading, spacing: 8) {
                                Text("EMAIL ADDRESS")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.gray)
                                
                                HStack {
                                    Image(systemName: "envelope")
                                        .foregroundColor(.gray)
                                    TextField("mail", text: $email)
                                        .keyboardType(.emailAddress)
                                        .textInputAutocapitalization(.never)
                                        .foregroundColor(.black)
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 52)
                                .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                                .cornerRadius(12)
                            }

                            // Password
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("PASSWORD")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Button("FORGOT?") {
                                    }
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.8))
                                }

                                HStack {
                                    Image(systemName: "lock")
                                        .foregroundColor(.gray)
                                    if isPasswordVisible {
                                        TextField("••••••••", text: $password)
                                            .foregroundColor(.black)
                                    } else {
                                        SecureField("••••••••", text: $password)
                                            .foregroundColor(.black)
                                    }
                                    Button(action: { isPasswordVisible.toggle() }) {
                                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 52)
                                .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                                .cornerRadius(12)
                            }

                            Spacer().frame(height: 4)

                            // Sign In Button
                            Button(action: {
                                Task {
                                    await authViewModel.signIn(email: email, password: password)
                                }
                            }) {
                                HStack {
                                    if authViewModel.isLoading {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text("Sign In")
                                            .font(.system(size: 16, weight: .semibold))
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color(red: 0.05, green: 0.15, blue: 0.55))
                                .cornerRadius(12)
                                .shadow(color: Color(red: 0.05, green: 0.15, blue: 0.55).opacity(0.3), radius: 10, y: 5)
                            }
                            .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty)

                            Spacer().frame(height: 8)

                            // Face ID Button
                            Button(action: {}) {
                                HStack {
                                    Image(systemName: "faceid")
                                        .font(.system(size: 18))
                                    Text("LOGIN WITH FACE ID")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(.gray)
                                .frame(width: 200, height: 44)
                                .background(Color.white)
                                .cornerRadius(22)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(Color(red: 0.9, green: 0.9, blue: 0.92), lineWidth: 1)
                                )
                            }
                        }
                        .padding(24)
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.03), radius: 20, y: 10)

                        Spacer().frame(height: 32)

                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationDestination(isPresented: $navigateToCreateAccount) {
                CreateAccountView()
            }
        }
    }
}

struct RoleSelectionButton: View {
    let item: RoleDisplayItem
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: item.iconName)
                .font(.system(size: 20))
                .foregroundColor(isSelected ? Color(red: 0.2, green: 0.3, blue: 0.7) : .gray)
            
            Text(item.roleName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? Color(red: 0.2, green: 0.3, blue: 0.7) : .gray)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(
            isSelected 
            ? Color(red: 0.2, green: 0.3, blue: 0.7).opacity(0.1) 
            : Color.white
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color(red: 0.2, green: 0.3, blue: 0.7) : Color(red: 0.9, green: 0.9, blue: 0.95), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(isSelected ? 0 : 0.02), radius: 5, y: 2)
    }
}
