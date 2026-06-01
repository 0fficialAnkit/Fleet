import SwiftUI

struct EditEmployeeView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: EmployeesViewModel

    @State private var originalProfile: Profile
    @State private var fullName: String
    @State private var email: String
    @State private var phone: String
    @State private var licenseNumber: String
    @State private var selectedStatus: UserStatus
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    let isDriverSelected: Bool

    init(profile: Profile, viewModel: EmployeesViewModel) {
        self.viewModel = viewModel
        _originalProfile = State(initialValue: profile)
        _fullName = State(initialValue: profile.fullName)
        _email = State(initialValue: profile.email)
        _phone = State(initialValue: profile.phone ?? "")
        _licenseNumber = State(initialValue: profile.licenseNumber ?? "")
        _selectedStatus = State(initialValue: profile.userStatus ?? .active)
        self.isDriverSelected = (profile.role == "driver")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personal Details")) {
                    TextField("Full Name", text: $fullName)
                        .textContentType(.name)
                    
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .textContentType(.emailAddress)
                    
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                    
                    if isDriverSelected {
                        TextField("Driver License Number", text: $licenseNumber)
                    }
                }
                
                Section(header: Text("Account Status")) {
                    Picker("Status", selection: $selectedStatus) {
                        ForEach([UserStatus.active, .inactive], id: \.self) { status in
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(status == .active ? Color.green : Color.secondary)
                                    .frame(width: 8, height: 8)
                                Text(status.rawValue.capitalized)
                            }
                            .tag(status)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .navigationTitle(isDriverSelected ? "Edit Driver" : "Edit Maintenance Staff")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.teal)
                    .disabled(isLoading)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        guard !fullName.isEmpty else { return }
                        isLoading = true
                        var updatedProfile = originalProfile
                        updatedProfile.fullName = fullName
                        updatedProfile.email = email
                        updatedProfile.phone = phone.isEmpty ? nil : phone
                        updatedProfile.licenseNumber = isDriverSelected && !licenseNumber.isEmpty ? licenseNumber : nil
                        updatedProfile.status = selectedStatus.rawValue

                        Task {
                            do {
                                try await ProfileService.updateProfile(updatedProfile)
                                await viewModel.loadData()
                                dismiss()
                            } catch {
                                isLoading = false
                                errorMessage = error.localizedDescription
                                showError = true
                                print("Error updating profile: \(error)")
                            }
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Save")
                                .bold()
                        }
                    }
                    .foregroundStyle(Color.teal)
                    .disabled(fullName.isEmpty || isLoading)
                }
            }
        }
    }
}

#Preview {
    EditEmployeeView(profile: Profile(id: UUID(), fullName: "Test User", email: "test@fleet.in", role: "driver"), viewModel: EmployeesViewModel())
}