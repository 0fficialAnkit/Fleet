import SwiftUI
import Supabase

struct AddEmployeeView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: EmployeesViewModel
    let roleName: String

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var phone = ""
    @State private var licenseNumber = ""
    @State private var isPasswordVisible = false

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
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // Error message
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(Color.red)
                                .padding(.horizontal, 16)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Personal Details")
                                .padding(.horizontal, 16)

                                VStack(spacing: 0) {
                                    TextField("Full Name", text: $fullName)
                                        .padding(.vertical, 12)
                                        .foregroundColor(Color.primary)

                                    Divider().background(Color(.separator))

                                    TextField("Email", text: $email)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .padding(.vertical, 12)
                                        .foregroundColor(Color.primary)

                                    Divider().background(Color(.separator))

                                    HStack {
                                        if isPasswordVisible {
                                            TextField("Password", text: $password)
                                                .foregroundColor(Color.primary)
                                        } else {
                                            SecureField("Password", text: $password)
                                                .foregroundColor(Color.primary)
                                        }

                                        Button(action: {
                                            isPasswordVisible.toggle()
                                        }) {
                                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                                .foregroundColor(Color.secondary)
                                        }
                                    }
                                    .padding(.vertical, 12)

                                    Divider().background(Color(.separator))

                                    TextField("Phone", text: $phone)
                                        .keyboardType(.phonePad)
                                        .padding(.vertical, 12)
                                        .foregroundColor(Color.primary)

                                    if isDriverSelected {
                                        Divider().background(Color(.separator))

                                        TextField("Driver License Number", text: $licenseNumber)
                                            .padding(.vertical, 12)
                                            .foregroundColor(Color.primary)
                                    }
                                }
                                .padding(16)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                                )

                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(isDriverSelected ? "Add Driver" : "Add Maintenance Staff")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.teal)
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
                    .foregroundColor(Color.teal)
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
                                .font(.body.weight(.medium))
                                .foregroundColor(.white)
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
    AddEmployeeView(viewModel: EmployeesViewModel(), roleName: "driver")
}