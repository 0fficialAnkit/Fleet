import SwiftUI

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = ProfileViewModel()
    @State private var isEditing = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                if let user = viewModel.currentUser {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Header Profile Image
                            ProfileHeader(
                                icon: "shield.checkered",
                                name: user.fullName,
                                role: viewModel.roleName,
                                accentColor: Color.purple
                            )
                            .padding(.top, 32)
                            
                            // Info Cards
                            
                                VStack(spacing: 0) {
                                    InfoRow(icon: "envelope.fill", label: "Email", value: user.email)
                                    
                                    Divider().background(Color(UIColor.separator))
                                    InfoRow(icon: "phone.fill", label: "Phone", value: user.phone ?? "N/A")
                                    
                                    if let status = user.userStatus {
                                        Divider().background(Color(UIColor.separator))
                                        InfoRow(
                                            icon: status == .active ? "checkmark.seal.fill" : "xmark.seal.fill",
                                            label: "Status",
                                            value: status.rawValue.capitalized,
                                            valueColor: status == .active ? Color.green : Color.secondary
                                        )
                                    }
                                    
                                    if let date = user.createdAt {
                                        Divider().background(Color(UIColor.separator))
                                        InfoRow(icon: "calendar", label: "Joined", value: date.formatted(date: .abbreviated, time: .omitted))
                                    }
                                }
                                .padding(16)
                                .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
                            .padding(.horizontal, 16)
                            
                            // Settings & Support Sections
                            
                                VStack(spacing: 0) {
                                    ActionRow(icon: "gearshape.fill", title: "Settings")
                                    Divider().background(Color(UIColor.separator))
                                    ActionRow(icon: "questionmark.circle.fill", title: "Help & Support")
                                }
                                .padding(16)
                                .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
                            .padding(.horizontal, 16)
                            
                            // Logout Button
                            
VStack(spacing: 0) {
                                Button(action: {
                                    Task {
                                        await authViewModel.signOut()
                                    }
                                }) {
                                    ActionRow(icon: "door.left.hand.open", title: "Logout", isDestructive: true)
                                }
                            }
                            .padding(16)
                            .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        }
                        .padding(.vertical, 16)
                    }
                } else {
                    Text("Profile not found")
                        .foregroundColor(Color.secondary)
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        isEditing = true
                    }
                    .foregroundColor(Color.blue)
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
    
    @State var fullName: String
    @State var phone: String
    
    var onSave: (String, String) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personal Info")) {
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
                    .disabled(fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
