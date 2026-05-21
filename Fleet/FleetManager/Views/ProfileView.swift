import SwiftUI

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    @Environment(AuthViewModel.self) private var authViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()
                
                if let user = viewModel.currentUser {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: themeModel.spacingLG) {
                            // Header Profile Image
                            VStack(spacing: themeModel.spacingSM) {
                                ZStack {
                                    Circle()
                                        .fill(themeModel.analyticsPurple.opacity(0.15))
                                        .frame(width: 110, height: 110)
                                    
                                    Image(systemName: "person.badge.shield.checkmark.fill")
                                        .font(.system(size: 44))
                                        .foregroundColor(themeModel.analyticsPurple)
                                }
                                .padding(.bottom, 8)
                                
                                Text(user.fullName)
                                    .font(themeModel.largeTitle(28))
                                    .foregroundColor(themeModel.textPrimary)
                                
                                Text(viewModel.roleName)
                                    .font(themeModel.bodyMedium(14))
                                    .foregroundColor(themeModel.analyticsPurple)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .background(themeModel.analyticsPurple.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                            .padding(.top, themeModel.spacingXL)
                            
                            // Info Cards
                            VStack(spacing: 0) {
                                ProfileInfoRow(icon: "envelope.fill", title: "Email", value: user.email)
                                
                                if let phone = user.phone {
                                    Divider().background(themeModel.divider).padding(.leading, 50)
                                    ProfileInfoRow(icon: "phone.fill", title: "Phone", value: phone)
                                }
                                
                                if let status = user.status {
                                    Divider().background(themeModel.divider).padding(.leading, 50)
                                    ProfileInfoRow(
                                        icon: status == .active ? "checkmark.seal.fill" : "xmark.seal.fill",
                                        title: "Status",
                                        value: status.rawValue.capitalized,
                                        valueColor: status == .active ? themeModel.success : themeModel.textSecondary
                                    )
                                }
                                
                                if let date = user.createdAt {
                                    Divider().background(themeModel.divider).padding(.leading, 50)
                                    ProfileInfoRow(icon: "calendar", title: "Joined", value: date.formatted(date: .abbreviated, time: .omitted))
                                }
                            }
                            .background(themeModel.backgroundElevated)
                            .cornerRadius(themeModel.radiusLG)
                            .padding(.horizontal, themeModel.spacingMD)
                            
                            // Settings & Support Sections
                            VStack(spacing: 0) {
                                ProfileActionRow(icon: "gearshape.fill", title: "Settings")
                                Divider().background(themeModel.divider).padding(.leading, 50)
                                ProfileActionRow(icon: "questionmark.circle.fill", title: "Help & Support")
                            }
                            .background(themeModel.backgroundElevated)
                            .cornerRadius(themeModel.radiusLG)
                            .padding(.horizontal, themeModel.spacingMD)
                            
                            // Logout Button
                            Button(action: {
                                Task {
                                    await authViewModel.signOut()
                                }
                            }) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Logout")
                                    Spacer()
                                }
                                .font(themeModel.headline(18))
                                .foregroundColor(themeModel.danger)
                                .padding()
                                .background(themeModel.backgroundElevated)
                                .cornerRadius(themeModel.radiusLG)
                            }
                            .padding(.horizontal, themeModel.spacingMD)
                            .padding(.top, themeModel.spacingMD)
                        }
                        .padding(.vertical, themeModel.spacingMD)
                    }
                } else {
                    Text("Profile not found")
                        .foregroundColor(themeModel.textSecondary)
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        // edit action
                    }
                    .foregroundColor(themeModel.info)
                }
            }
        }
    }
}

struct ProfileInfoRow: View {
    let icon: String
    let title: String
    let value: String
    var valueColor: Color = themeModel.textPrimary
    
    var body: some View {
        HStack(spacing: themeModel.spacingMD) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(themeModel.textTertiary)
                .frame(width: 30)
            
            Text(title)
                .font(themeModel.bodyMedium(16))
                .foregroundColor(themeModel.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(themeModel.body(16))
                .foregroundColor(valueColor)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
    }
}

struct ProfileActionRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: themeModel.spacingMD) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(themeModel.textTertiary)
                .frame(width: 30)
            
            Text(title)
                .font(themeModel.bodyMedium(16))
                .foregroundColor(themeModel.textPrimary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(themeModel.textTertiary)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
    }
}

#Preview {
    ProfileView()
}
