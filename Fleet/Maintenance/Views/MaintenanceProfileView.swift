import SwiftUI

struct MaintenanceProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var profileVM = ProfileViewModel()

    // Profile menu items
    private let menuItems: [(title: String, icon: String, isDestructive: Bool)] = [
        ("Certifications", "rosette", false),
        ("Shift Schedule", "calendar", false),
        ("Assigned Depot", "building.2.fill", false),
        ("Notifications", "bell", false),
        ("Performance Report", "chart.bar.xaxis", false)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: themeModel.spacingLG) {

                        // MARK: - Profile Header
                        ProfileHeader(
                            icon: "person.crop.circle.fill",
                            name: profileVM.currentUser?.fullName ?? "Mechanic",
                            role: "Senior Mechanic",
                            accentColor: themeModel.maintenancePrimary
                        )
                        .padding(.top, themeModel.spacingMD)

                        // MARK: - Stats Strip
                        HStack(spacing: themeModel.spacingMD) {
                            StatPill(value: "—", label: "Orders Done", color: themeModel.maintenancePrimary)
                            StatPill(value: "—", label: "Accuracy", color: themeModel.success)
                            StatPill(value: "—", label: "Rating", color: themeModel.warning)
                        }
                        .padding(.horizontal, themeModel.spacingMD)

                        // MARK: - Menu
                        VStack(spacing: 0) {
                            ForEach(menuItems, id: \.title) { item in
                                Button(action: {}) {
                                    ActionRow(
                                        icon: item.icon,
                                        title: item.title,
                                        iconColor: themeModel.maintenancePrimary,
                                        isDestructive: item.isDestructive
                                    )
                                }
                                .buttonStyle(.plain)

                                if item.title != menuItems.last?.title {
                                    Divider()
                                        .background(themeModel.divider)
                                        .padding(.leading, 42)
                                }
                            }
                        }
                        .padding(.horizontal, themeModel.spacingMD)
                        .padding(.vertical, themeModel.spacingSM)
                        .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                        )
                        .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
                        .padding(.horizontal, themeModel.spacingMD)

                        // MARK: - Logout
                        Button(action: {
                            Task { await authViewModel.signOut() }
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                            }
                            .font(themeModel.bodyMedium())
                            .foregroundStyle(themeModel.danger)
                            .frame(maxWidth: .infinity)
                            .padding(themeModel.spacingMD)
                            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                                    .stroke(themeModel.danger.opacity(0.25), lineWidth: 0.8)
                            )
                            .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
                        }
                        .padding(.horizontal, themeModel.spacingMD)
                        .padding(.bottom, themeModel.spacingLG)
                    }
                }
            }
            .navigationTitle("Profile")
        }
        .task {
            await profileVM.loadProfile()
        }
    }
}

// MARK: - Stat Pill
private struct StatPill: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(themeModel.headline())
                .foregroundStyle(color)
            Text(label)
                .font(themeModel.small())
                .foregroundStyle(themeModel.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, themeModel.spacingMD)
        .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous)
                .stroke(color.opacity(0.2), lineWidth: 0.8)
        )
    }
}

#Preview {
    MaintenanceProfileView()
        .environment(AuthViewModel())
}
