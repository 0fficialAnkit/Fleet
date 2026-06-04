import SwiftUI

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ProfileViewModel()
    @State private var isEditing = false
    @State private var showingChangePassword = false

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

                        // Change Password
                        Section {
                            Button { showingChangePassword = true } label: {
                                Label("Change Password", systemImage: "key.fill")
                                    .foregroundStyle(.primary)
                            }
                        }

                        // Sign out
                        Section {
                            Button(role: .destructive) {
                                Task { await authViewModel.signOut() }
                            } label: {
                                Label {
                                    Text("Sign Out")
                                } icon: {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.body)
                                        .foregroundStyle(.red)
                                }
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
            .sheet(isPresented: $showingChangePassword) {
                ChangePasswordSheetView()
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
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(fullName, phone)
                        dismiss()
                    }
                    .font(.headline)
                    .disabled(fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
