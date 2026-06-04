import SwiftUI

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ProfileViewModel()
    @State private var isEditing = false

    var body: some View {
        NavigationStack {
            Group {
                if let user = viewModel.currentUser {
                    List {
                        // Header
                        Section {
                            HStack {
                                Spacer()
                                VStack(spacing: 10) {
                                    ProfileHeader(
                                        icon: "shield.checkered",
                                        name: user.fullName,
                                        role: viewModel.roleName,
                                        accentColor: .teal
                                    )
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .listRowBackground(Color.clear)
                        }

                        // Info
                        Section("Account") {
                            InfoRow(icon: "envelope.fill", label: "Email", value: user.email)
                            InfoRow(icon: "phone.fill",    label: "Phone", value: user.phone ?? "Not set")
                            if let status = user.userStatus {
                                InfoRow(
                                    icon: status == .active ? "checkmark.seal.fill" : "xmark.seal.fill",
                                    label: "Status",
                                    value: status.rawValue.capitalized,
                                    valueColor: status == .active ? .green : .secondary
                                )
                            }
                            if let date = user.createdAt {
                                InfoRow(icon: "calendar", label: "Joined",
                                        value: date.formatted(date: .abbreviated, time: .omitted))
                            }
                        }

                        // Support
                        Section {
                            Label("Settings", systemImage: "gearshape")
                            Label("Help & Support", systemImage: "questionmark.circle")
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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") { isEditing = true }
                        .foregroundStyle(.primary)
                }
            }
            .sheet(isPresented: $isEditing) {
                if let user = viewModel.currentUser {
                    EditProfileSheet(
                        fullName: user.fullName,
                        phone: user.phone ?? "",
                        onSave: { newName, newPhone in
                            Task {
                                await viewModel.updateProfile(fullName: newName, phone: newPhone)
                                await authViewModel.fetchProfile()
                            }
                        }
                    )
                }
            }
        }
        .task {
            await viewModel.loadProfile()
        }
    }
}

#Preview {
    ProfileView()
        .environment(AuthViewModel())
}

struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var fullName: String
    @State private var phone: String

    var onSave: (String, String) -> Void

    init(fullName: String, phone: String, onSave: @escaping (String, String) -> Void) {
        self._fullName = State(initialValue: fullName)
        self._phone    = State(initialValue: phone)
        self.onSave    = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Info") {
                    TextField("Full Name", text: $fullName)
                        .textContentType(.name)
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }

                Section {
                    Button("Save Changes") {
                        onSave(fullName, phone)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(.label))
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .disabled(fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
