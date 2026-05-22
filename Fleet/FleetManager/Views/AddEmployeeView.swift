import SwiftUI

struct AddEmployeeView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: EmployeesViewModel
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var licenseNumber = ""
    @State private var selectedRoleId: UUID?
    
    var isDriverSelected: Bool {
        guard let id = selectedRoleId, let role = viewModel.roles.first(where: { $0.id == id }) else { return false }
        return role.roleName.lowercased() == "driver"
    }
    
    var assignableRoles: [Role] {
        viewModel.roles.filter { $0.roleName.lowercased() != "fleet manager" }
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
                                    
                                    TextField("Phone", text: $phone)
                                        .keyboardType(.phonePad)
                                        .padding(.vertical, 12)
                                        .foregroundColor(themeModel.textPrimary)
                                    
                                    Divider().background(themeModel.divider)
                                    
                                    TextField("Driver License Number", text: $licenseNumber)
                                        .padding(.vertical, 12)
                                        .foregroundColor(isDriverSelected ? themeModel.textPrimary : themeModel.textDisabled)
                                        .disabled(!isDriverSelected)
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
                        
                        VStack(alignment: .leading, spacing: themeModel.spacingSM) {
                            SectionHeader(title: "Role & Access")
                                .padding(.horizontal, themeModel.spacingMD)
                            
                            
VStack(spacing: 0) {
                                Picker("Select Role", selection: $selectedRoleId) {
                                    Text("Select a role").tag(UUID?.none)
                                    ForEach(assignableRoles) { role in
                                        Text(role.roleName).tag(UUID?.some(role.id))
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(themeModel.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                            
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
            .navigationTitle("Add Employee")
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
                        if let roleId = selectedRoleId, !fullName.isEmpty {
                            viewModel.addEmployee(
                                fullName: fullName,
                                email: email,
                                phone: phone,
                                licenseNumber: isDriverSelected && !licenseNumber.isEmpty ? licenseNumber : nil,
                                roleId: roleId
                            )
                            dismiss()
                        }
                    }
                    .foregroundColor(themeModel.accent)
                    .bold()
                    .disabled(fullName.isEmpty || selectedRoleId == nil)
                }
            }
        }
    }
}

#Preview {
    AddEmployeeView(viewModel: EmployeesViewModel())
}
