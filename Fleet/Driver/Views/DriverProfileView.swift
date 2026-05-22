import SwiftUI

struct DriverProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var profileVM = ProfileViewModel()

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(spacing: 32) {

                    ProfileHeader(
                        icon: "person.crop.circle.fill",
                        name: profileVM.currentUser?.fullName ?? "Driver",
                        role: "Fleet Driver",
                        accentColor: themeModel.driverPrimary
                    )

                    VStack(spacing: 16) {
                        
                        
                            VStack(spacing: 12) {
                                InfoRow(icon: "bell.badge", label: "Notifications", value: "Enabled")
                                Divider()
                                InfoRow(icon: "doc.text.fill", label: "Documents", value: "Verified")
                                Divider()
                                InfoRow(icon: "lifepreserver", label: "Support", value: "Online")
                            }
                            .padding(themeModel.spacingMD)
                            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                            )
                            .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)

                        
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
                    }
                }
                .padding()
            }
            .background(themeModel.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Profile")
        }
        .task {
            await profileVM.loadProfile()
        }
    }
}

#Preview {
    DriverProfileView()
        .environment(AuthViewModel())
}
