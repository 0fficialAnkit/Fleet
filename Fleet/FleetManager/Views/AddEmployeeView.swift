import SwiftUI
import Supabase

struct AddEmployeeView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: EmployeesViewModel
    
    @State private var selectedRole: String

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var phone = ""
    @State private var licenseNumber = ""
    @State private var isPasswordVisible = false

    init(viewModel: EmployeesViewModel, initialRole: String = "driver") {
        self.viewModel = viewModel
        self._selectedRole = State(initialValue: initialRole)
    }

    var isDriverSelected: Bool {
        return selectedRole == "driver"
    }

    /// Map display role to database role string
    var dbRole: String {
        isDriverSelected ? "driver" : "maintenance"
    }

    var body: some View {
        NavigationStack {
                Form {


                    if let error = viewModel.errorMessage {
                        Section {
                            Text(error)
                                .foregroundStyle(.red)
                        }
                    }

                    Section(header: Text("Personal Details")) {
                        TextField("Full Name", text: $fullName)
                            .textContentType(.name)

                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .textContentType(.emailAddress)

                        HStack {
                            if isPasswordVisible {
                                TextField("Password", text: $password)
                                    .textContentType(.newPassword)
                            } else {
                                SecureField("Password", text: $password)
                                    .textContentType(.newPassword)
                            }

                            Button(action: {
                                isPasswordVisible.toggle()
                            }) {
                                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        TextField("Phone", text: $phone)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)

                        if isDriverSelected {
                            TextField("Driver License Number", text: $licenseNumber)
                        }
                    }
                }
            .navigationTitle(isDriverSelected ? "Add Driver" : "Add Maintenance Staff")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
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
                            } catch let error as NSError where error.domain == "ProfileService" {
                                viewModel.errorMessage = error.localizedDescription
                            } catch {
                                // Supabase functions error might contain a body
                                if let functionsError = error as? FunctionsError {
                                    switch functionsError {
                                    case .httpError(let code, let data):
                                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                                           let serverError = json["error"] as? String {
                                            viewModel.errorMessage = "Server Error (\(code)): \(serverError)"
                                        } else {
                                            viewModel.errorMessage = "HTTP Error \(code)"
                                        }
                                    case .relayError:
                                        viewModel.errorMessage = "Network relay error"
                                    }
                                } else {
                                    viewModel.errorMessage = error.localizedDescription
                                }
                            }
                        }
                    }
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
                                .tint(.white)
                                .scaleEffect(1.2)
                            Text("Creating user...")
                                .font(.body.weight(.medium))
                                .foregroundStyle(.white)
                        }
                        .padding(32)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }
            }
        }
    }
}

#Preview {
    AddEmployeeView(viewModel: EmployeesViewModel())
}