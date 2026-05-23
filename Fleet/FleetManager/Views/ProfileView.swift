import SwiftUI

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = ProfileViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()
                
                if let user = viewModel.currentUser {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: themeModel.spacingLG) {
                            // Header Profile Image
                            ProfileHeader(
                                icon: "shield.checkered",
                                name: user.fullName,
                                role: viewModel.roleName,
                                accentColor: themeModel.analyticsPurple
                            )
                            .padding(.top, themeModel.spacingXL)
                            
                            // Info Cards
                            
                                VStack(spacing: 0) {
                                    InfoRow(icon: "envelope.fill", label: "Email", value: user.email)
                                    
                                    if let phone = user.phone {
                                        Divider().background(themeModel.divider)
                                        InfoRow(icon: "phone.fill", label: "Phone", value: phone)
                                    }
                                    
                                    if let status = user.userStatus {
                                        Divider().background(themeModel.divider)
                                        InfoRow(
                                            icon: status == .active ? "checkmark.seal.fill" : "xmark.seal.fill",
                                            label: "Status",
                                            value: status.rawValue.capitalized,
                                            valueColor: status == .active ? themeModel.success : themeModel.textSecondary
                                        )
                                    }
                                    
                                    if let date = user.createdAt {
                                        Divider().background(themeModel.divider)
                                        InfoRow(icon: "calendar", label: "Joined", value: date.formatted(date: .abbreviated, time: .omitted))
                                    }
                                }
                                .padding(themeModel.spacingMD)
                                .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                                )
                                .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
                            .padding(.horizontal, themeModel.spacingMD)
                            
                            // Settings & Support Sections
                            
                                VStack(spacing: 0) {
                                    ActionRow(icon: "gearshape.fill", title: "Settings")
                                    Divider().background(themeModel.divider)
                                    ActionRow(icon: "questionmark.circle.fill", title: "Help & Support")
                                }
                                .padding(themeModel.spacingMD)
                                .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                                )
                                .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
                            .padding(.horizontal, themeModel.spacingMD)
                            
                            // Logout Button
                            
VStack(spacing: 0) {
                                Button(action: {
                                    Task {
                                        await authViewModel.signOut()
                                    }
                                }) {
                                    ActionRow(icon: "door.left.hand.open", title: "Logout", isDestructive: true)
                                }
                            }
                            .padding(themeModel.spacingMD)
                            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                            )
                            .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
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
                    .foregroundColor(themeModel.accent)
                }
            }
        }
        .task {
            await viewModel.loadProfile()
        }
    }
}

#Preview {
    ProfileView()
        .environment(AuthViewModel())
}
