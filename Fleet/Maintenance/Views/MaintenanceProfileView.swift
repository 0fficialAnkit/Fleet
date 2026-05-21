import SwiftUI

struct MaintenanceProfileView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: themeModel.spacingLG) {
                        ProfileHeader(
                            icon: "wrench.and.screwdriver.fill",
                            name: "Mike Thompson",
                            role: "Senior Mechanic",
                            accentColor: themeModel.maintenancePrimary
                        )

                        
                            VStack(spacing: 0) {
                                ActionRow(icon: "rosette", title: "Certifications")
                                Divider().background(themeModel.textTertiary.opacity(0.3)).padding(.leading, 40)
                                ActionRow(icon: "calendar.badge.clock", title: "Shift Schedule")
                                Divider().background(themeModel.textTertiary.opacity(0.3)).padding(.leading, 40)
                                ActionRow(icon: "building.2", title: "Assigned Depot")
                                Divider().background(themeModel.textTertiary.opacity(0.3)).padding(.leading, 40)
                                ActionRow(icon: "bell.badge", title: "Notifications")
                            }
                            .padding(themeModel.spacingMD)
                            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
//                            .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)

                        
VStack(spacing: 0) {
                            ActionRow(icon: "door.left.hand.open", title: "Logout", isDestructive: true)
                        
                        }
                        .padding(themeModel.spacingMD)
                        .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                        )
//                        .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
                    }
                    .padding(themeModel.spacingMD)
                }
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    MaintenanceProfileView()
}
