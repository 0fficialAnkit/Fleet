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
                Form {
                    if let error = errorMessage {
                        Section {
                            Text(error)
                                .foregroundColor(.red)
                        }
                    }

                    Section(header: Text("Basic Details")) {
                        TextField("Manufacturer (e.g. Ford)", text: $make)
                        TextField("Model (e.g. Transit)", text: $model)
                        TextField("Year (e.g. 2024)", text: $year)
                            .keyboardType(.numberPad)
                        TextField("License Plate", text: $licensePlate)
                            .textInputAutocapitalization(.characters)
                    }

                    Section(header: Text("Specifications")) {
                        TextField("Tank Capacity (L)", text: $tankCapacity)
                            .keyboardType(.decimalPad)
                        TextField("Mileage (km/l)", text: $mileage)
                            .keyboardType(.decimalPad)
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
