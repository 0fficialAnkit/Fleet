import SwiftUI

struct AddEmployeeView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: EmployeesViewModel
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var licenseNumber = ""
    @State private var selectedRoleId: UUID?
    
    init(viewModel: EmployeesViewModel, preselectedRoleName: String? = nil) {
        self.viewModel = viewModel
        
        if let roleName = preselectedRoleName,
           let role = viewModel.roles.first(where: { $0.roleName.lowercased() == roleName.lowercased() }) {
            _selectedRoleId = State(initialValue: role.id)
        }
    }
    
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
                    
                    if isDriverSelected {
                        TextField("Driver License Number", text: $licenseNumber)
                            .foregroundColor(themeModel.textPrimary)
                    }
                }
                .listRowBackground(themeModel.backgroundElevated)
                

            }
            .scrollContentBackground(.hidden)
            .background(themeModel.backgroundPrimary)
            .navigationTitle(isDriverSelected ? "Add Driver" : "Add Maintenance")
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
    AddEmployeeView(viewModel: EmployeesViewModel(), preselectedRoleName: "driver")
}

