import SwiftUI

struct DriverProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var profileVM = ProfileViewModel()
    @State private var showingChangePassword = false

    var body: some View {
        NavigationStack {
            List {
                // Header
                Section {
                    HStack {
                        Spacer()
                        ProfileHeader(
                            icon: "person.crop.circle.fill",
                            name: profileVM.currentUser?.fullName ?? "Driver",
                            role: "Fleet Driver",
                            accentColor: .green
                        )
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                }

                // Personal info
                Section("Personal Information") {
                    InfoRow(icon: "person.fill",       label: "Full Name", value: profileVM.currentUser?.fullName ?? "—")
                    InfoRow(icon: "envelope.fill",     label: "Email",     value: profileVM.currentUser?.email ?? "—")
                    InfoRow(icon: "phone.fill",        label: "Phone",     value: profileVM.currentUser?.phone ?? "Not Provided")
                    InfoRow(icon: "lanyardcard.fill",  label: "License",   value: profileVM.currentUser?.licenseNumber ?? "Not Provided")
                    let status = profileVM.currentUser?.userStatus ?? .active
                    InfoRow(
                        icon: status == .active ? "checkmark.seal.fill" : "xmark.seal.fill",
                        label: "Status",
                        value: status.rawValue.capitalized,
                        valueColor: status == .active ? .green : .secondary
                    )
                    if let date = profileVM.currentUser?.createdAt {
                        InfoRow(icon: "calendar", label: "Joined",
                                value: date.formatted(date: .abbreviated, time: .omitted))
                    }
                }

                // Account actions
                Section {
                    Button { showingChangePassword = true } label: {
                        Label("Change Password", systemImage: "key")
                    }

                    Button(role: .destructive) {
                        Task { await authViewModel.signOut() }
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .task { await profileVM.loadProfile() }
            .sheet(isPresented: $showingChangePassword) {
                ChangePasswordSheetView()
            }
        }
    }
}

#Preview {
    DriverProfileView()
        .environment(AuthViewModel())
}
