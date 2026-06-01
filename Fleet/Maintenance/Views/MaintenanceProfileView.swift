import SwiftUI

struct MaintenanceProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var profileVM = ProfileViewModel()

    // Profile menu items
    private let menuItems: [(title: String, icon: String, isDestructive: Bool)] = [
        ("Certifications", "rosette", false),
        ("Performance Report", "chart.bar.xaxis", false),
        ("Notifications", "bell", false)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // MARK: - Profile Header
                        ProfileHeader(
                            icon: "person.crop.circle.fill",
                            name: profileVM.currentUser?.fullName ?? "Mechanic",
                            role: "Senior Mechanic",
                            accentColor: Color.brown
                        )
                        .padding(.top, 16)


                        // MARK: - Personal Information
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Personal Information")
                                .font(.body.bold())
                                .foregroundStyle(Color.primary)
                                .padding(.bottom, 4)

                            InfoRow(
                                icon: "person.fill",
                                label: "Full Name",
                                value: profileVM.currentUser?.fullName ?? "—",
                                iconColor: Color.brown
                            )

                            Divider().background(Color(.separator))
                            InfoRow(
                                icon: "envelope.fill",
                                label: "Email",
                                value: profileVM.currentUser?.email ?? "—",
                                iconColor: Color.brown
                            )

                            Divider().background(Color(.separator))
                            InfoRow(
                                icon: "phone.fill",
                                label: "Phone",
                                value: profileVM.currentUser?.phone ?? "Not Provided",
                                iconColor: Color.brown
                            )

                            Divider().background(Color(.separator))
                            let status = profileVM.currentUser?.userStatus ?? .active
                            InfoRow(
                                icon: status == .active ? "checkmark.circle.fill" : "xmark.circle.fill",
                                label: "Status / State",
                                value: status.rawValue.capitalized,
                                iconColor: status == .active ? Color.green : Color.secondary,
                                valueColor: status == .active ? Color.green : Color.secondary
                            )

                            Divider().background(Color(.separator))
                            InfoRow(
                                icon: "calendar",
                                label: "Joined",
                                value: profileVM.currentUser?.createdAt?.formatted(date: .abbreviated, time: .omitted) ?? "—",
                                iconColor: Color.brown
                            )
                        }
                        .padding(16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                        )

                        .padding(.horizontal, 16)

                        // MARK: - Menu
                        VStack(spacing: 0) {
                            ForEach(menuItems, id: \.title) { item in
                                Group {
                                    if item.title == "Certifications" {
                                        NavigationLink {
                                            CertificationsView()
                                        } label: {
                                            ActionRow(
                                                icon: item.icon,
                                                title: item.title,
                                                iconColor: Color.brown,
                                                isDestructive: item.isDestructive
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    } else if item.title == "Performance Report" {
                                        NavigationLink {
                                            PerformanceReportView()
                                        } label: {
                                            ActionRow(
                                                icon: item.icon,
                                                title: item.title,
                                                iconColor: Color.brown,
                                                isDestructive: item.isDestructive
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        Button(action: {}) {
                                            ActionRow(
                                                icon: item.icon,
                                                title: item.title,
                                                iconColor: Color.brown,
                                                isDestructive: item.isDestructive
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }

                                if item.title != menuItems.last?.title {
                                    Divider()
                                        .background(Color(.separator))
                                        .padding(.leading, 42)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                        )

                        .padding(.horizontal, 16)

                        // MARK: - Logout
                        Button(action: {
                            Task { await authViewModel.signOut() }
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                            }
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.red)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.red.opacity(0.25), lineWidth: 0.8)
                            )

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
                .font(.headline)
                .foregroundStyle(color)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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