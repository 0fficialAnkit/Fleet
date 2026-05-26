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
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // MARK: - Profile Header
                        ProfileHeader(
                            icon: "person.crop.circle.fill",
                            name: profileVM.currentUser?.fullName ?? "Mechanic",
                            role: "Senior Mechanic",
                            accentColor: Color.orange
                        )
                        .padding(.top, 16)

                        // MARK: - Stats Strip
                        HStack(spacing: 16) {
                            StatPill(value: "—", label: "Orders Done", color: Color.orange)
                            StatPill(value: "—", label: "Accuracy", color: Color.green)
                            StatPill(value: "—", label: "Rating", color: Color.yellow)
                        }
                        .padding(.horizontal, 16)

                        // MARK: - Personal Information
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Personal Information")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.primary)
                                .padding(.bottom, 4)
                            
                            InfoRow(
                                icon: "person.fill",
                                label: "Full Name",
                                value: profileVM.currentUser?.fullName ?? "—",
                                iconColor: Color.orange
                            )

                            Divider().background(Color(UIColor.separator))
                            InfoRow(
                                icon: "envelope.fill",
                                label: "Email",
                                value: profileVM.currentUser?.email ?? "—",
                                iconColor: Color.orange
                            )
                            
                            Divider().background(Color(UIColor.separator))
                            InfoRow(
                                icon: "phone.fill",
                                label: "Phone",
                                value: profileVM.currentUser?.phone ?? "Not Provided",
                                iconColor: Color.orange
                            )
                            
                            Divider().background(Color(UIColor.separator))
                            let status = profileVM.currentUser?.userStatus ?? .active
                            InfoRow(
                                icon: status == .active ? "checkmark.circle.fill" : "xmark.circle.fill",
                                label: "Status / State",
                                value: status.rawValue.capitalized,
                                iconColor: status == .active ? Color.green : Color.secondary,
                                valueColor: status == .active ? Color.green : Color.secondary
                            )
                            
                            Divider().background(Color(UIColor.separator))
                            InfoRow(
                                icon: "calendar",
                                label: "Joined",
                                value: profileVM.currentUser?.createdAt?.formatted(date: .abbreviated, time: .omitted) ?? "—",
                                iconColor: Color.orange
                            )
                        }
                        .padding(16)
                        .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
                        .padding(.horizontal, 16)

                        // MARK: - Menu
                        VStack(spacing: 0) {
                            ForEach(menuItems, id: \.title) { item in
                                Button(action: {}) {
                                    ActionRow(
                                        icon: item.icon,
                                        title: item.title,
                                        iconColor: Color.orange,
                                        isDestructive: item.isDestructive
                                    )
                                }
                                .buttonStyle(.plain)

                                if item.title != menuItems.last?.title {
                                    Divider()
                                        .background(Color(UIColor.separator))
                                        .padding(.leading, 42)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
                        .padding(.horizontal, 16)

                        // MARK: - Logout
                        Button(action: {
                            Task { await authViewModel.signOut() }
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                            }
                            .font(.system(size: , weight: .medium, design: .rounded))
                            .foregroundStyle(Color.red)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.red.opacity(0.25), lineWidth: 0.8)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
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
                .font(.system(size: , weight: .semibold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: , weight: .medium, design: .rounded))
                .foregroundStyle(Color(UIColor.tertiaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .glassEffect(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(color.opacity(0.2), lineWidth: 0.8)
        )
    }
}

#Preview {
    MaintenanceProfileView()
        .environment(AuthViewModel())
}
