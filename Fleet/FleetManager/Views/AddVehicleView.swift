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
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: themeModel.spacingLG) {
                        
                        // Basic Details Section
                        VStack(alignment: .leading, spacing: themeModel.spacingSM) {
                            SectionHeader(title: "Basic Details")
                                .padding(.horizontal, themeModel.spacingMD)
                            
                            VStack(spacing: 0) {
                                TextField("Manufacturer (e.g. Ford)", text: $make)
                                    .padding(.vertical, 12)
                                    .foregroundColor(themeModel.textPrimary)
                                
                                Divider().background(themeModel.divider)
                                
                                TextField("Model (e.g. Transit)", text: $model)
                                    .padding(.vertical, 12)
                                    .foregroundColor(themeModel.textPrimary)
                                    
                                Divider().background(themeModel.divider)
                                
                                TextField("Year (e.g. 2024)", text: $year)
                                    .keyboardType(.numberPad)
                                    .padding(.vertical, 12)
                                    .foregroundColor(themeModel.textPrimary)
                                
                                Divider().background(themeModel.divider)
                                
                                TextField("License Plate", text: $licensePlate)
                                    .textInputAutocapitalization(.characters)
                                    .padding(.vertical, 12)
                                    .foregroundColor(themeModel.textPrimary)
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
                        
                        // Specifications Section
                        VStack(alignment: .leading, spacing: themeModel.spacingSM) {
                            SectionHeader(title: "Specifications")
                                .padding(.horizontal, themeModel.spacingMD)
                            
                            VStack(spacing: 0) {
                                TextField("Tank Capacity (L)", text: $tankCapacity)
                                    .keyboardType(.decimalPad)
                                    .padding(.vertical, 12)
                                    .foregroundColor(themeModel.textPrimary)
                                
                                Divider().background(themeModel.divider)
                                
                                TextField("Mileage (km/l)", text: $mileage)
                                    .keyboardType(.decimalPad)
                                    .padding(.vertical, 12)
                                    .foregroundColor(themeModel.textPrimary)
                                
                                Divider().background(themeModel.divider)
                                
                                DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                                    .padding(.vertical, 12)
                                    .foregroundColor(themeModel.textPrimary)
                                    .tint(themeModel.info)
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
                        let yearInt = Int(year.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 2024
                        let cap = Double(tankCapacity.trimmingCharacters(in: .whitespacesAndNewlines))
                        let mil = Double(mileage.trimmingCharacters(in: .whitespacesAndNewlines))
                        
                        viewModel.addVehicle(
                            make: make.isEmpty ? "Unknown" : make,
                            model: model.isEmpty ? "Unknown" : model,
                            year: yearInt,
                            tankCapacity: cap,
                            mileage: mil,
                            purchaseDate: purchaseDate,
                            licensePlate: licensePlate.isEmpty ? "NO-PLATE" : licensePlate
                        )
                        dismiss()
                    }
                    .foregroundColor(themeModel.info)
                    .bold()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    AddVehicleView(viewModel: VehiclesViewModel())
}
