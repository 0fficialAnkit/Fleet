import SwiftUI

struct EditEmployeeView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: EmployeesViewModel
    
    @State private var originalProfile: Profile
    @State private var fullName: String
    @State private var email: String
    @State private var phone: String
    @State private var licenseNumber: String
    
    let isDriverSelected: Bool
    
    init(profile: Profile, viewModel: EmployeesViewModel) {
        self.viewModel = viewModel
        _originalProfile = State(initialValue: profile)
        _fullName = State(initialValue: profile.fullName)
        _email = State(initialValue: profile.email)
        _phone = State(initialValue: profile.phone ?? "")
        _licenseNumber = State(initialValue: profile.licenseNumber ?? "")
        self.isDriverSelected = (profile.role == "driver")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Personal Details")
                                .padding(.horizontal, 16)
                            
                                VStack(spacing: 0) {
                                    TextField("Full Name", text: $fullName)
                                        .padding(.vertical, 12)
                                        .foregroundColor(Color.primary)
                                    
                                    Divider().background(Color(UIColor.separator))
                                    
                                    TextField("Email", text: $email)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .padding(.vertical, 12)
                                        .foregroundColor(Color.primary)
                                    
                                    Divider().background(Color(UIColor.separator))
                                    
                                    TextField("Phone", text: $phone)
                                        .keyboardType(.phonePad)
                                        .padding(.vertical, 12)
                                        .foregroundColor(Color.primary)
                                    
                                    if isDriverSelected {
                                        Divider().background(Color(UIColor.separator))
                                        
                                        TextField("Driver License Number", text: $licenseNumber)
                                            .padding(.vertical, 12)
                                            .foregroundColor(Color.primary)
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
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(isDriverSelected ? "Edit Driver" : "Edit Maintenance Staff")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.blue)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !fullName.isEmpty else { return }
                        var updatedProfile = originalProfile
                        updatedProfile.fullName = fullName
                        updatedProfile.email = email
                        updatedProfile.phone = phone.isEmpty ? nil : phone
                        updatedProfile.licenseNumber = isDriverSelected && !licenseNumber.isEmpty ? licenseNumber : nil
                        
                        Task {
                            do {
                                try await ProfileService.updateProfile(updatedProfile)
                                await viewModel.loadData()
                                dismiss()
                            } catch {
                                print("Error updating profile: \(error)")
                            }
                        }
                    }
                    .foregroundColor(Color.blue)
                    .bold()
                    .disabled(fullName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    EditEmployeeView(profile: Profile(id: UUID(), fullName: "Test User", email: "test@fleet.in", role: "driver"), viewModel: EmployeesViewModel())
}
