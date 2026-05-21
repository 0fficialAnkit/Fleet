import SwiftUI

struct EditVehicleView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: VehiclesViewModel
    
    @State private var vehicle: Vehicle
    @State private var make: String
    @State private var model: String
    @State private var year: String
    @State private var licensePlate: String
    @State private var tankCapacity: String
    @State private var mileage: String
    @State private var purchaseDate: Date
    
    init(vehicle: Vehicle, viewModel: VehiclesViewModel) {
        self.viewModel = viewModel
        _vehicle = State(initialValue: vehicle)
        _make = State(initialValue: vehicle.make ?? "")
        _model = State(initialValue: vehicle.model ?? "")
        _year = State(initialValue: vehicle.year != nil ? String(vehicle.year!) : "")
        _licensePlate = State(initialValue: vehicle.licensePlate ?? "")
        _tankCapacity = State(initialValue: vehicle.tankCapacity != nil ? String(vehicle.tankCapacity!) : "")
        _mileage = State(initialValue: vehicle.mileage != nil ? String(vehicle.mileage!) : "")
        _purchaseDate = State(initialValue: vehicle.purchaseDate ?? Date())
    }
    
    var isFormValid: Bool {
        !make.isEmpty && !model.isEmpty && !year.isEmpty && !licensePlate.isEmpty && Int(year) != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Details").foregroundColor(themeModel.textSecondary)) {
                    TextField("Manufacturer (e.g. Ford)", text: $make)
                        .foregroundColor(themeModel.textPrimary)
                    TextField("Model (e.g. Transit)", text: $model)
                        .foregroundColor(themeModel.textPrimary)
                    TextField("Year (e.g. 2024)", text: $year)
                        .keyboardType(.numberPad)
                        .foregroundColor(themeModel.textPrimary)
                    TextField("License Plate", text: $licensePlate)
                        .textInputAutocapitalization(.characters)
                        .foregroundColor(themeModel.textPrimary)
                }
                .listRowBackground(themeModel.backgroundElevated)
                
                Section(header: Text("Specifications").foregroundColor(themeModel.textSecondary)) {
                    TextField("Tank Capacity (L)", text: $tankCapacity)
                        .keyboardType(.decimalPad)
                        .foregroundColor(themeModel.textPrimary)
                    TextField("Mileage (km/l)", text: $mileage)
                        .keyboardType(.decimalPad)
                        .foregroundColor(themeModel.textPrimary)
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                        .foregroundColor(themeModel.textPrimary)
                        .tint(themeModel.info)
                }
                .listRowBackground(themeModel.backgroundElevated)
            }
            .scrollContentBackground(.hidden)
            .background(themeModel.backgroundPrimary)
            .navigationTitle("Edit Vehicle")
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
                        if let yearInt = Int(year) {
                            var updatedVehicle = vehicle
                            updatedVehicle.make = make
                            updatedVehicle.model = model
                            updatedVehicle.year = yearInt
                            updatedVehicle.licensePlate = licensePlate
                            updatedVehicle.tankCapacity = Double(tankCapacity)
                            updatedVehicle.mileage = Double(mileage)
                            updatedVehicle.purchaseDate = purchaseDate
                            
                            viewModel.updateVehicle(updatedVehicle)
                            dismiss()
                        }
                    }
                    .foregroundColor(themeModel.info)
                    .bold()
                    .disabled(!isFormValid)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    EditVehicleView(vehicle: MockData.vehicles.first!, viewModel: VehiclesViewModel())
}
