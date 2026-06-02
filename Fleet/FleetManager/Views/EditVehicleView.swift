import SwiftUI

struct EditVehicleView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: VehiclesViewModel
    var vehicle: Vehicle

    @State private var make: String
    @State private var model: String
    @State private var year: String
    @State private var licensePlate: String
    @State private var tankCapacity: String
    @State private var mileage: String
    @State private var purchaseDate: Date
    @State private var selectedType: VehicleType

    init(viewModel: VehiclesViewModel, vehicle: Vehicle) {
        self.viewModel = viewModel
        self.vehicle = vehicle

        _make = State(initialValue: vehicle.make ?? "")
        _model = State(initialValue: vehicle.model ?? "")
        _year = State(initialValue: vehicle.year != nil ? String(vehicle.year!) : "")
        _licensePlate = State(initialValue: vehicle.licensePlate ?? "")
        _tankCapacity = State(initialValue: vehicle.tankCapacity != nil ? String(vehicle.tankCapacity!) : "")
        _mileage = State(initialValue: vehicle.mileage != nil ? String(vehicle.mileage!) : "")
        _purchaseDate = State(initialValue: vehicle.purchaseDate ?? Date())
        _selectedType = State(initialValue: vehicle.vehicleType ?? .car)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // Basic Details Section
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Basic Details")
                                .padding(.horizontal, 16)

                            VStack(spacing: 0) {
                                TextField("", text: $make, prompt: Text("Manufacturer (e.g. Ford)").foregroundStyle(Color(.placeholderText)))
                                    .padding(.vertical, 12)
                                    .foregroundStyle(Color.primary)

                                Divider().background(Color(.separator))

                                TextField("", text: $model, prompt: Text("Model (e.g. Transit)").foregroundStyle(Color(.placeholderText)))
                                    .padding(.vertical, 12)
                                    .foregroundStyle(Color.primary)

                                Divider().background(Color(.separator))

                                TextField("", text: $year, prompt: Text("Year (e.g. 2024)").foregroundStyle(Color(.placeholderText)))
                                    .keyboardType(.numberPad)
                                    .padding(.vertical, 12)
                                    .foregroundStyle(Color.primary)

                                Divider().background(Color(.separator))

                                TextField("", text: $licensePlate, prompt: Text("License Plate").foregroundStyle(Color(.placeholderText)))
                                    .textInputAutocapitalization(.characters)
                                    .padding(.vertical, 12)
                                    .foregroundStyle(Color.primary)
                                
                                Divider().background(Color(.separator))
                                
                                HStack {
                                    Text("Vehicle Type")
                                        .foregroundStyle(Color.primary)
                                    Spacer()
                                    Picker("", selection: $selectedType) {
                                        ForEach(VehicleType.allCases) { type in
                                            Text(type.displayName).tag(type)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                                .padding(.vertical, 8)
                            }
                            .padding(16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .padding(.horizontal, 16)
                        }

                        // Specifications Section
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Specifications")
                                .padding(.horizontal, 16)

                            VStack(spacing: 0) {
                                TextField("", text: $tankCapacity, prompt: Text("Tank Capacity (L)").foregroundStyle(Color(.placeholderText)))
                                    .keyboardType(.decimalPad)
                                    .padding(.vertical, 12)
                                    .foregroundStyle(Color.primary)

                                Divider().background(Color(.separator))

                                TextField("", text: $mileage, prompt: Text("Mileage (km/l)").foregroundStyle(Color(.placeholderText)))
                                    .keyboardType(.decimalPad)
                                    .padding(.vertical, 12)
                                    .foregroundStyle(Color.primary)

                                Divider().background(Color(.separator))

                                DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                                    .padding(.vertical, 12)
                                    .foregroundStyle(Color.primary)
                                    .tint(Color.teal)
                            }
                            .padding(16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Edit Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.teal)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let yearInt = Int(year.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 2024
                        let cap = Double(tankCapacity.trimmingCharacters(in: .whitespacesAndNewlines))
                        let mil = Double(mileage.trimmingCharacters(in: .whitespacesAndNewlines))

                        var updatedVehicle = vehicle
                        updatedVehicle.make = make.isEmpty ? "Unknown" : make
                        updatedVehicle.model = model.isEmpty ? "Unknown" : model
                        updatedVehicle.year = yearInt
                        updatedVehicle.licensePlate = licensePlate.isEmpty ? "NO-PLATE" : licensePlate
                        updatedVehicle.tankCapacity = cap
                        updatedVehicle.mileage = mil
                        updatedVehicle.purchaseDate = purchaseDate
                        updatedVehicle.vehicleType = selectedType

                        Task {
                            do {
                                try await viewModel.updateVehicle(updatedVehicle)
                                dismiss()
                            } catch {
                                viewModel.errorMessage = error.localizedDescription
                            }
                        }
                    }
                    .foregroundStyle(Color.teal)
                    .bold()
                }
            }
        }
    }
}
