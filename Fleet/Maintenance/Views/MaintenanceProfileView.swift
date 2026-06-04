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

                if let user = profileVM.currentUser {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {

                            // MARK: - Profile Header
                            ProfileHeader(
                                icon: "person.crop.circle.fill",
                                name: user.fullName,
                                role: "Senior Mechanic",
                                accentColor: Color.brown
                            )
                            .padding(.top, 32)

                            // MARK: - Personal Information
                            VStack(spacing: 0) {
                                InfoRow(
                                    icon: "person.fill",
                                    label: "Full Name",
                                    value: user.fullName,
                                    iconColor: Color.brown
                                )

                                Divider().background(Color(.separator))
                                InfoRow(
                                    icon: "envelope.fill",
                                    label: "Email",
                                    value: user.email,
                                    iconColor: Color.brown
                                )

                                Divider().background(Color(.separator))
                                InfoRow(
                                    icon: "phone.fill",
                                    label: "Phone",
                                    value: user.phone ?? "Not Provided",
                                    iconColor: Color.brown
                                )

                                Divider().background(Color(.separator))
                                let status = user.userStatus ?? .active
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
                                    value: user.createdAt?.formatted(date: .abbreviated, time: .omitted) ?? "—",
                                    iconColor: Color.brown
                                )
                            }
                            .padding(16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                        }
                        .padding(.vertical, 16)
                    }
                } else {
                    Text("Profile not found")
                        .foregroundStyle(Color.secondary)
                }
            }
            .navigationTitle("Profile")
        }
        .task {
            await profileVM.loadProfile()
        }
    }
}

#Preview {
    MaintenanceProfileView()
        .environment(AuthViewModel())
}