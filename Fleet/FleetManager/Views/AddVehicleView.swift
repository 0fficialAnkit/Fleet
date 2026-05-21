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
    @State private var purchaseDate = Date()
    
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
            .navigationTitle("Add Vehicle")
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
                            viewModel.addVehicle(
                                make: make,
                                model: model,
                                year: yearInt,
                                tankCapacity: Double(tankCapacity),
                                mileage: Double(mileage),
                                purchaseDate: purchaseDate,
                                licensePlate: licensePlate
                            )
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
    AddVehicleView(viewModel: VehiclesViewModel())
}
