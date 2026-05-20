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
            Form {
                Section(header: Text("Personal Details").foregroundColor(themeModel.textSecondary)) {
                    TextField("Full Name", text: $fullName)
                        .foregroundColor(themeModel.textPrimary)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .foregroundColor(themeModel.textPrimary)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                        .foregroundColor(themeModel.textPrimary)
                    
                    TextField("Driver License Number", text: $licenseNumber)
                        .foregroundColor(isDriverSelected ? themeModel.textPrimary : themeModel.textDisabled)
                        .disabled(!isDriverSelected)
                }
                .listRowBackground(themeModel.backgroundElevated)
                
                Section(header: Text("Role & Access").foregroundColor(themeModel.textSecondary)) {
                    Picker("Select Role", selection: $selectedRoleId) {
                        Text("Select a role").tag(UUID?.none)
                        ForEach(assignableRoles) { role in
                            Text(role.roleName).tag(UUID?.some(role.id))
                        }
                    }
                    .foregroundColor(themeModel.textPrimary)
                }
                .listRowBackground(themeModel.backgroundElevated)
            }
            .scrollContentBackground(.hidden)
            .background(themeModel.backgroundPrimary)
            .navigationTitle("Add Employee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(themeModel.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeModel.info)
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
                    .foregroundColor(themeModel.info)
                    .bold()
                    .disabled(fullName.isEmpty || selectedRoleId == nil)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    AddEmployeeView(viewModel: EmployeesViewModel())
}

