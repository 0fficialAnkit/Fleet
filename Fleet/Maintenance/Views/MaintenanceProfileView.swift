import SwiftUI

struct MaintenanceProfileView: View {
    @State private var showLogoutAlert = false

    // Menu items built as computed var so MBlue adaptive colors evaluate at render time.
    private var menuItems: [(title: String, icon: String, tint: Color)] {
        [
            ("Certifications",    "rosette",                            MBlue.accentLight),
            ("Shift Schedule",    "calendar",                           MBlue.inProgress),
            ("Assigned Depot",    "building.2.fill",                    MBlue.accent),
            ("Notifications",     "bell",                               MBlue.accentBright),
            ("Help & Support",    "questionmark.circle",                MBlue.textSecondary),
            ("Logout",            "rectangle.portrait.and.arrow.right", MBlue.critical)
        ]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground().ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // ── Avatar + Name ──
                        VStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [MBlue.accent, Color(hex: "#1E3A8A")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 90, height: 90)

                                Text("MT")
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)

                                // Online dot
                                Circle()
                                    .fill(MBlue.inProgress)
                                    .frame(width: 16, height: 16)
                                    .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 3))
                                    .offset(x: 32, y: 32)
                            }

                            VStack(spacing: 4) {
                                Text("Mike Thompson")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(MBlue.textPrimary)

                                Text("Senior Mechanic")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(MBlue.textSecondary)

                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(MBlue.inProgress)
                                        .frame(width: 6, height: 6)
                                    Text("On Duty · Depot A")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(MBlue.textMuted)
                                }
                                .padding(.top, 2)
                            }
                        }
                        .padding(.top, 8)

                        // ── Stats Strip ──
                        HStack(spacing: 0) {
                            ProfileStat(value: "127", label: "Jobs Done")
                            Divider().frame(height: 36)
                            ProfileStat(value: "4.9★", label: "Rating")
                            Divider().frame(height: 36)
                            ProfileStat(value: "6 yrs", label: "Experience")
                        }
                        .padding(.vertical, 12)
                        .mCard()
                        .padding(.horizontal)

                        // ── Menu Items ──
                        VStack(spacing: 0) {
                            ForEach(menuItems.indices, id: \.self) { idx in
                                let item = menuItems[idx]
                                ProfileMenuRow(
                                    title: item.title,
                                    icon: item.icon,
                                    tint: item.tint,
                                    showDivider: idx < menuItems.count - 1
                                )
                            }
                        }
                        .mCard()
                        .padding(.horizontal)

                        // ── Version ──
                        Text("Fleet Management System v2.4.1")
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundColor(MBlue.textMuted)
                            .padding(.bottom, 32)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Profile Stat Cell
struct ProfileStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(MBlue.textPrimary)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(MBlue.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Profile Menu Row
struct ProfileMenuRow: View {
    let title: String
    let icon: String
    let tint: Color
    let showDivider: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(tint.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(tint)
                        .symbolRenderingMode(.hierarchical)
                }

                Text(title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(MBlue.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MBlue.textMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)

            if showDivider {
                Rectangle()
                    .fill(MBlue.divider)
                    .frame(height: 1)
                    .padding(.leading, 66)
            }
        }
    }
}

#Preview {
    MaintenanceProfileView()
}
