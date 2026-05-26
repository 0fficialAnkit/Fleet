import SwiftUI

struct AddVehicleView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: VehiclesViewModel

    @State private var make = ""
    @State private var model = ""
    @State private var year = ""
    @State private var licensePlate = ""
    @State private var tankCapacity = ""
    @State private var mileage = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // Error message
                        if let error = errorMessage {
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(Color.red)
                                .padding(.horizontal, 16)
                        }

                        // Basic Details Section
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Basic Details")
                                .padding(.horizontal, 16)
                                                        VStack(spacing: 0) {
                                TextField("", text: $make, prompt: Text("Manufacturer (e.g. Ford)").foregroundColor(Color(.placeholderText)))
                                    .padding(.vertical, 12)
                                    .foregroundColor(Color.primary)

                                Divider().background(Color(.separator))

                                TextField("", text: $model, prompt: Text("Model (e.g. Transit)").foregroundColor(Color(.placeholderText)))
                                    .padding(.vertical, 12)
                                    .foregroundColor(Color.primary)

                                Divider().background(Color(.separator))

                                TextField("", text: $year, prompt: Text("Year (e.g. 2024)").foregroundColor(Color(.placeholderText)))
                                    .keyboardType(.numberPad)
                                    .padding(.vertical, 12)
                                    .foregroundColor(Color.primary)

                                Divider().background(Color(.separator))

                                TextField("", text: $licensePlate, prompt: Text("License Plate").foregroundColor(Color(.placeholderText)))
                                    .textInputAutocapitalization(.characters)
                                    .padding(.vertical, 12)
                                    .foregroundColor(Color.primary)
                            }
                            .padding(16)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                            )

                            .padding(.horizontal, 16)
                        }

                        // Specifications Section
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Specifications")
                                .padding(.horizontal, 16)
                                                        VStack(spacing: 0) {
                                TextField("", text: $tankCapacity, prompt: Text("Tank Capacity (L)").foregroundColor(Color(.placeholderText)))
                                    .keyboardType(.decimalPad)
                                    .padding(.vertical, 12)
                                    .foregroundColor(Color.primary)

                                Divider().background(Color(.separator))

                                TextField("", text: $mileage, prompt: Text("Mileage (km/l)").foregroundColor(Color(.placeholderText)))
                                    .keyboardType(.decimalPad)
                                    .padding(.vertical, 12)
                                    .foregroundColor(Color.primary)
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
            .navigationTitle("Add Vehicle")
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
                        Task {
                            isSaving = true
                            errorMessage = nil
                            let yearInt = Int(year.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 2024
                            let cap = Double(tankCapacity.trimmingCharacters(in: .whitespacesAndNewlines))
                            let mil = Double(mileage.trimmingCharacters(in: .whitespacesAndNewlines))

                            let makeTrimmed = make.trimmingCharacters(in: .whitespacesAndNewlines)
                            let modelTrimmed = model.trimmingCharacters(in: .whitespacesAndNewlines)
                            let plateTrimmed = licensePlate.trimmingCharacters(in: .whitespacesAndNewlines)

                            guard !makeTrimmed.isEmpty, !modelTrimmed.isEmpty, !plateTrimmed.isEmpty else {
                                errorMessage = "Make, model, and license plate are required."
                                isSaving = false
                                return
                            }

                            do {
                                try await viewModel.addVehicle(
                                    make: makeTrimmed,
                                    model: modelTrimmed,
                                    year: yearInt,
                                    tankCapacity: cap,
                                    mileage: mil,
                                    licensePlate: plateTrimmed
                                )
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isSaving = false
                        }
                    }
                    .foregroundColor(Color.teal)
                    .bold()
                    .disabled(isSaving)
                }
            }
            .overlay {
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                            Text("Adding vehicle...")
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
    AddVehicleView(viewModel: VehiclesViewModel())
}
