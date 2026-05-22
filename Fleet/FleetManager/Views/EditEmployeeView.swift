import SwiftUI

struct EditEmployeeView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: EmployeesViewModel
    
    @State private var user: User
    @State private var fullName: String
    @State private var email: String
    @State private var phone: String
    @State private var licenseNumber: String
    @State private var selectedRoleId: UUID?
    
    init(user: User, viewModel: EmployeesViewModel) {
        self.viewModel = viewModel
        _user = State(initialValue: user)
        _fullName = State(initialValue: user.fullName)
        _email = State(initialValue: user.email)
        _phone = State(initialValue: user.phone ?? "")
        _licenseNumber = State(initialValue: user.licenseNumber ?? "")
        _selectedRoleId = State(initialValue: user.roleId)
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
            .navigationTitle(isDriverSelected ? "Edit Driver" : "Edit Maintenance")
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
                            var updatedUser = user
                            updatedUser.fullName = fullName
                            updatedUser.email = email
                            updatedUser.phone = phone.isEmpty ? nil : phone
                            updatedUser.licenseNumber = isDriverSelected && !licenseNumber.isEmpty ? licenseNumber : nil
                            updatedUser.roleId = roleId
                            
                            viewModel.updateEmployee(updatedUser)
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
    EditEmployeeView(user: MockData.users.first!, viewModel: EmployeesViewModel())
}
