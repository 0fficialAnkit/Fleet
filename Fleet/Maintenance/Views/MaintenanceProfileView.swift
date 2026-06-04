import SwiftUI

struct MaintenanceProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var profileVM = ProfileViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if let user = profileVM.currentUser {
                    List {
                        // Header
                        Section {
                            HStack {
                                Spacer()
                                ProfileHeader(
                                    icon: "person.crop.circle.fill",
                                    name: user.fullName,
                                    role: "Maintenance Staff",
                                    accentColor: .brown
                                )
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .listRowBackground(Color.clear)
                        }

                        // Personal info
                        Section("Personal Information") {
                            InfoRow(icon: "person.fill",    label: "Full Name", value: user.fullName)
                            InfoRow(icon: "envelope.fill",  label: "Email",     value: user.email)
                            InfoRow(icon: "phone.fill",     label: "Phone",     value: user.phone ?? "Not Provided")
                            let status = user.userStatus ?? .active
                            InfoRow(
                                icon: status == .active ? "checkmark.seal.fill" : "xmark.seal.fill",
                                label: "Status",
                                value: status.rawValue.capitalized,
                                valueColor: status == .active ? .green : .secondary
                            )
                            if let date = user.createdAt {
                                InfoRow(icon: "calendar", label: "Joined",
                                        value: date.formatted(date: .abbreviated, time: .omitted))
                            }
                        }

                        // Navigation links
                        Section {
                            NavigationLink(destination: CertificationsView()) {
                                Label("Certifications", systemImage: "rosette")
                            }
                            NavigationLink(destination: PerformanceReportView()) {
                                Label("Performance Report", systemImage: "chart.bar.xaxis")
                            }
                            Label("Notifications", systemImage: "bell")
                        }

                        // Sign out
                        Section {
                            Button(role: .destructive) {
                                Task { await authViewModel.signOut() }
                            } label: {
                                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                } else {
                    ContentUnavailableView("Profile not found", systemImage: "person.slash")
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task { await profileVM.loadProfile() }
    }
}

#Preview {
    MaintenanceProfileView()
        .environment(AuthViewModel())
}
