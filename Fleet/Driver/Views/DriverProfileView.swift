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
                    accentColor: Color.green
                )

                VStack(spacing: 20) {
                    // Personal Information Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Personal Information")
                            .font(.body.bold())
                            .foregroundStyle(Color.primary)
                            .padding(.bottom, 4)

                        InfoRow(
                            icon: "person.fill",
                            label: "Full Name",
                            value: profileVM.currentUser?.fullName ?? "—",
                            iconColor: Color.green
                        )

                        Divider().background(Color(.separator))
                        InfoRow(
                            icon: "envelope.fill",
                            label: "Email",
                            value: profileVM.currentUser?.email ?? "—",
                            iconColor: Color.green
                        )

                        Divider().background(Color(.separator))
                        InfoRow(
                            icon: "phone.fill",
                            label: "Phone",
                            value: profileVM.currentUser?.phone ?? "Not Provided",
                            iconColor: Color.green
                        )

                        Divider().background(Color(.separator))
                        InfoRow(
                            icon: "lanyardcard.fill",
                            label: "License",
                            value: profileVM.currentUser?.licenseNumber ?? "Not Provided",
                            iconColor: Color.green
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
                            iconColor: Color.green
                        )
                    }
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    )

                    // Preferences & Support Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Preferences & Support")
                            .font(.body.bold())
                            .foregroundStyle(Color.primary)
                            .padding(.bottom, 4)

                        InfoRow(
                            icon: "bell",
                            label: "Notifications",
                            value: "Enabled",
                            iconColor: Color.green
                        )
                        Divider().background(Color(.separator))
                        InfoRow(
                            icon: "doc.text.fill",
                            label: "Documents",
                            value: "Verified",
                            iconColor: Color.green
                        )
                        Divider().background(Color(.separator))
                        InfoRow(
                            icon: "lifepreserver",
                            label: "Support",
                            value: "Online",
                            iconColor: Color.green
                        )
                    }
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    )

                    // Logout Button
                    Button(action: {
                        Task {
                            await authViewModel.signOut()
                        }
                    }) {
                        ActionRow(
                            icon: "door.left.hand.open",
                            title: "Logout",
                            iconColor: Color.green,
                            isDestructive: true
                        )
                    }
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    )

                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
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