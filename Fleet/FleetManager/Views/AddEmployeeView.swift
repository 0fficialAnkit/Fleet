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
    
    /// Map display role to database role string
    var dbRole: String {
        isDriverSelected ? "driver" : "maintenance"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: themeModel.spacingLG) {
                        
                        // Error message
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(themeModel.caption(14))
                                .foregroundColor(themeModel.danger)
                                .padding(.horizontal, themeModel.spacingMD)
                        }
                        
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
                        guard !fullName.isEmpty, !email.isEmpty, !password.isEmpty else { return }
                        Task {
                            do {
                                try await viewModel.addEmployee(
                                    fullName: fullName,
                                    email: email,
                                    password: password,
                                    phone: phone,
                                    licenseNumber: isDriverSelected && !licenseNumber.isEmpty ? licenseNumber : nil,
                                    role: dbRole
                                )
                                dismiss()
                            } catch {
                                viewModel.errorMessage = error.localizedDescription
                            }
                        }
                    }
                    .foregroundColor(themeModel.accent)
                    .bold()
                    .disabled(fullName.isEmpty || email.isEmpty || password.isEmpty || viewModel.isCreatingUser)
                }
            }
            .overlay {
                if viewModel.isCreatingUser {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                            Text("Creating user...")
                                .font(themeModel.bodyMedium())
                                .foregroundColor(.white)
                        }
                        .padding(32)
                        .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                    }
                }
            }
        }
    }
}

#Preview {
    AddEmployeeView(viewModel: EmployeesViewModel(), roleName: "driver")
}
