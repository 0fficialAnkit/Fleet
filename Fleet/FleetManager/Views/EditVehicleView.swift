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
    @State private var isSaving = false

    init(viewModel: VehiclesViewModel, vehicle: Vehicle) {
        self.viewModel = viewModel
        self.vehicle   = vehicle
        _make         = State(initialValue: vehicle.make ?? "")
        _model        = State(initialValue: vehicle.model ?? "")
        _year         = State(initialValue: vehicle.year.map(String.init) ?? "")
        _licensePlate = State(initialValue: vehicle.licensePlate ?? "")
        _tankCapacity = State(initialValue: vehicle.tankCapacity.map { String(format: "%.0f", $0) } ?? "")
        _mileage      = State(initialValue: vehicle.mileage.map { String(format: "%.0f", $0) } ?? "")
        _purchaseDate = State(initialValue: vehicle.purchaseDate ?? Date())
        _selectedType = State(initialValue: vehicle.vehicleType ?? .car)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // Basic Details
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Basic Details")
                                .padding(.horizontal, 16)

                            VStack(spacing: 0) {
                                TextField("", text: $make,
                                          prompt: Text("Manufacturer (e.g. Ford)").foregroundStyle(Color(.placeholderText)))
                                    .padding(.vertical, 12).foregroundStyle(Color.primary)
                                Divider().background(Color(.separator))

                                TextField("", text: $model,
                                          prompt: Text("Model (e.g. Transit)").foregroundStyle(Color(.placeholderText)))
                                    .padding(.vertical, 12).foregroundStyle(Color.primary)
                                Divider().background(Color(.separator))

                                TextField("", text: $year,
                                          prompt: Text("Year (e.g. 2024)").foregroundStyle(Color(.placeholderText)))
                                    .keyboardType(.numberPad)
                                    .padding(.vertical, 12).foregroundStyle(Color.primary)
                                Divider().background(Color(.separator))

                                TextField("", text: $licensePlate,
                                          prompt: Text("Licence Plate").foregroundStyle(Color(.placeholderText)))
                                    .textInputAutocapitalization(.characters)
                                    .autocorrectionDisabled()
                                    .padding(.vertical, 12).foregroundStyle(Color.primary)
                                Divider().background(Color(.separator))

                                HStack {
                                    Text("Vehicle Type").foregroundStyle(Color.primary)
                                    Spacer()
                                    Picker("", selection: $selectedType) {
                                        ForEach(VehicleType.allCases) { type in
                                            Text(type.displayName).tag(type)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(Color.primary)
                                }
                                .padding(.vertical, 8)
                            }
                            .padding(16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .padding(.horizontal, 16)
                        }

                        // Specifications
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Specifications")
                                .padding(.horizontal, 16)

                            VStack(spacing: 0) {
                                TextField("", text: $tankCapacity,
                                          prompt: Text("Tank Capacity (L)").foregroundStyle(Color(.placeholderText)))
                                    .keyboardType(.numberPad)
                                    .padding(.vertical, 12).foregroundStyle(Color.primary)
                                Divider().background(Color(.separator))

                                TextField("", text: $mileage,
                                          prompt: Text("Fuel Economy (km/L)").foregroundStyle(Color(.placeholderText)))
                                    .keyboardType(.numberPad)
                                    .padding(.vertical, 12).foregroundStyle(Color.primary)
                                Divider().background(Color(.separator))

                                DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                                    .padding(.vertical, 12).foregroundStyle(Color.primary)
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
                    Button("Cancel") { dismiss() }.foregroundStyle(Color.teal)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") { save() }
                            .foregroundStyle(Color.teal).bold()
                    }
                }
            }
        }
    }

    private func save() {
        isSaving = true
        var updated = vehicle
        updated.make         = make.isEmpty ? nil : make.trimmingCharacters(in: .whitespaces)
        updated.model        = model.isEmpty ? nil : model.trimmingCharacters(in: .whitespaces)
        updated.year         = Int(year)
        updated.licensePlate = licensePlate.isEmpty ? nil : licensePlate.trimmingCharacters(in: .whitespaces).uppercased()
        updated.tankCapacity = Double(tankCapacity)
        updated.mileage      = Double(mileage)
        updated.purchaseDate = purchaseDate
        updated.vehicleType  = selectedType

        Task {
            do {
                // Saves to DB + triggers loadData() → realtime → all screens update
                try await viewModel.updateVehicle(updated)
                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run {
                    viewModel.errorMessage = error.localizedDescription
                    isSaving = false
                }
            }
        }
    }
}

#Preview {
    EditVehicleView(
        viewModel: VehiclesViewModel(),
        vehicle: Vehicle(id: UUID(), make: "Ford", model: "Transit", year: 2024,
                         vin: "123456789", licensePlate: "FL-99-TR",
                         tankCapacity: 80.0, mileage: 12.4, purchaseDate: Date(),
                         assignedDriverId: nil, adminId: nil, status: .active)
    )
}
