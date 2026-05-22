import SwiftUI

struct AddEmployeeView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: EmployeesViewModel
    let roleName: String
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var phone = ""
    @State private var licenseNumber = ""
    
    var isDriverSelected: Bool {
        return roleName.lowercased() == "driver"
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
                                    
                                    SecureField("Password", text: $password)
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
            .navigationTitle(isDriverSelected ? "Add Driver" : "Add Maintenance Staff")
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
                        if let role = viewModel.roles.first(where: { $0.roleName.lowercased() == roleName.lowercased() }), !fullName.isEmpty {
                            viewModel.addEmployee(
                                fullName: fullName,
                                email: email,
                                phone: phone,
                                licenseNumber: isDriverSelected && !licenseNumber.isEmpty ? licenseNumber : nil,
                                roleId: role.id,
                                passwordHash: password // Mocking hashing
                            )
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
    AddEmployeeView(viewModel: EmployeesViewModel(), roleName: "driver")
}
