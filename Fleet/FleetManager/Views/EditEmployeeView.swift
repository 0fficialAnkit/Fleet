import SwiftUI

struct EditEmployeeView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: EmployeesViewModel
    
    @State private var user: User
    @State private var fullName: String
    @State private var email: String
    @State private var password = "" // Blank unless they want to change it
    @State private var phone: String
    @State private var licenseNumber: String
    
    let isDriverSelected: Bool
    
    init(user: User, viewModel: EmployeesViewModel) {
        self.viewModel = viewModel
        _user = State(initialValue: user)
        _fullName = State(initialValue: user.fullName)
        _email = State(initialValue: user.email)
        _phone = State(initialValue: user.phone ?? "")
        _licenseNumber = State(initialValue: user.licenseNumber ?? "")
        
        let roleName = viewModel.getRole(for: user)?.roleName.lowercased() ?? ""
        self.isDriverSelected = (roleName == "driver")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: themeModel.spacingLG) {
                        
                        VStack(alignment: .leading, spacing: themeModel.spacingSM) {
                            SectionHeader(title: "Personal Details")
                                .padding(.horizontal, themeModel.spacingMD)
                            
                                VStack(spacing: 0) {
                                    TextField("Full Name", text: $fullName)
                                        .padding(.vertical, 12)
                                        .foregroundColor(themeModel.textPrimary)
                                    
                                    Divider().background(themeModel.divider)
                                    
                                    TextField("Email", text: $email)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .padding(.vertical, 12)
                                        .foregroundColor(themeModel.textPrimary)
                                        
                                    Divider().background(themeModel.divider)
                                    
                                    SecureField("New Password (optional)", text: $password)
                                        .padding(.vertical, 12)
                                        .foregroundColor(themeModel.textPrimary)
                                    
                                    Divider().background(themeModel.divider)
                                    
                                    TextField("Phone", text: $phone)
                                        .keyboardType(.phonePad)
                                        .padding(.vertical, 12)
                                        .foregroundColor(themeModel.textPrimary)
                                    
                                    if isDriverSelected {
                                        Divider().background(themeModel.divider)
                                        
                                        TextField("Driver License Number", text: $licenseNumber)
                                            .padding(.vertical, 12)
                                            .foregroundColor(themeModel.textPrimary)
                                    }
                                }
                                .padding(themeModel.spacingMD)
                                .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                                )
                                .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
                            .padding(.horizontal, themeModel.spacingMD)
                        }
                    }
                    .padding(.vertical, themeModel.spacingMD)
                }
            }
            .navigationTitle(isDriverSelected ? "Edit Driver" : "Edit Maintenance Staff")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeModel.accent)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if !fullName.isEmpty {
                            var updatedUser = user
                            updatedUser.fullName = fullName
                            updatedUser.email = email
                            updatedUser.phone = phone.isEmpty ? nil : phone
                            updatedUser.licenseNumber = isDriverSelected && !licenseNumber.isEmpty ? licenseNumber : nil
                            
                            // Only update password if they typed a new one
                            if !password.isEmpty {
                                updatedUser.passwordHash = password // Mocking hashing
                            }
                            
                            viewModel.updateEmployee(updatedUser)
                            dismiss()
                        }
                    }
                    .foregroundColor(themeModel.accent)
                    .bold()
                    .disabled(fullName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    EditEmployeeView(user: MockData.users.first!, viewModel: EmployeesViewModel())
}
