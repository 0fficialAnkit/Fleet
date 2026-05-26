import SwiftUI

struct DriverProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var profileVM = ProfileViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                ProfileHeader(
                    icon: "person.crop.circle.fill",
                    name: profileVM.currentUser?.fullName ?? "Driver",
                    role: "Fleet Driver",
                    accentColor: themeModel.driverPrimary
                )

                VStack(spacing: 20) {
                    // Personal Information Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Personal Information")
                            .font(themeModel.headline(16))
                            .foregroundStyle(themeModel.textPrimary)
                            .padding(.bottom, 4)
                        
                        InfoRow(
                            icon: "person.fill",
                            label: "Full Name",
                            value: profileVM.currentUser?.fullName ?? "—",
                            iconColor: themeModel.driverPrimary
                        )

                        Divider().background(themeModel.divider)
                        InfoRow(
                            icon: "envelope.fill",
                            label: "Email",
                            value: profileVM.currentUser?.email ?? "—",
                            iconColor: themeModel.driverPrimary
                        )
                        
                        Divider().background(themeModel.divider)
                        InfoRow(
                            icon: "phone.fill",
                            label: "Phone",
                            value: profileVM.currentUser?.phone ?? "Not Provided",
                            iconColor: themeModel.driverPrimary
                        )
                        
                        Divider().background(themeModel.divider)
                        InfoRow(
                            icon: "lanyardcard.fill",
                            label: "License",
                            value: profileVM.currentUser?.licenseNumber ?? "Not Provided",
                            iconColor: themeModel.driverPrimary
                        )
                        
                        Divider().background(themeModel.divider)
                        let status = profileVM.currentUser?.userStatus ?? .active
                        InfoRow(
                            icon: status == .active ? "checkmark.circle.fill" : "xmark.circle.fill",
                            label: "Status / State",
                            value: status.rawValue.capitalized,
                            iconColor: status == .active ? themeModel.success : themeModel.textSecondary,
                            valueColor: status == .active ? themeModel.success : themeModel.textSecondary
                        )
                        
                        Divider().background(themeModel.divider)
                        InfoRow(
                            icon: "calendar",
                            label: "Joined",
                            value: profileVM.currentUser?.createdAt?.formatted(date: .abbreviated, time: .omitted) ?? "—",
                            iconColor: themeModel.driverPrimary
                        )
                    }
                    .padding(themeModel.spacingMD)
                    .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    )
                    .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)

                    // Preferences & Support Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Preferences & Support")
                            .font(themeModel.headline(16))
                            .foregroundStyle(themeModel.textPrimary)
                            .padding(.bottom, 4)

                        InfoRow(
                            icon: "bell",
                            label: "Notifications",
                            value: "Enabled",
                            iconColor: themeModel.driverPrimary
                        )
                        Divider().background(themeModel.divider)
                        InfoRow(
                            icon: "doc.text.fill",
                            label: "Documents",
                            value: "Verified",
                            iconColor: themeModel.driverPrimary
                        )
                        Divider().background(themeModel.divider)
                        InfoRow(
                            icon: "lifepreserver",
                            label: "Support",
                            value: "Online",
                            iconColor: themeModel.driverPrimary
                        )
                    }
                    .padding(themeModel.spacingMD)
                    .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    )
                    .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)

                    // Logout Button
                    Button(action: {
                        Task {
                            await authViewModel.signOut()
                        }
                    }) {
                        ActionRow(
                            icon: "door.left.hand.open",
                            title: "Logout",
                            iconColor: themeModel.driverPrimary,
                            isDestructive: true
                        )
                    }
                    .padding(themeModel.spacingMD)
                    .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    )
                    .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
                }
            }
            .padding()
        }
        .background(themeModel.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Profile")
        .task {
            await profileVM.loadProfile()
        }
    }
}

#Preview {
    DriverProfileView()
        .environment(AuthViewModel())
}
