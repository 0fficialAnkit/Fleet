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
                themeModel.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: themeModel.spacingLG) {
                        
                        // Error message
                        if let error = errorMessage {
                            Text(error)
                                .font(themeModel.caption(14))
                                .foregroundColor(themeModel.danger)
                                .padding(.horizontal, themeModel.spacingMD)
                        }
                        
                        // Basic Details Section
                        VStack(alignment: .leading, spacing: themeModel.spacingSM) {
                            SectionHeader(title: "Basic Details")
                                .padding(.horizontal, themeModel.spacingMD)
                                                        VStack(spacing: 0) {
                                TextField("", text: $make, prompt: Text("Manufacturer (e.g. Ford)").foregroundColor(themeModel.placeholder))
                                    .padding(.vertical, 12)
                                    .foregroundColor(themeModel.textPrimary)
                                
                                Divider().background(themeModel.divider)
                                
                                TextField("", text: $model, prompt: Text("Model (e.g. Transit)").foregroundColor(themeModel.placeholder))
                                    .padding(.vertical, 12)
                                    .foregroundColor(themeModel.textPrimary)
                                    
                                Divider().background(themeModel.divider)
                                
                                TextField("", text: $year, prompt: Text("Year (e.g. 2024)").foregroundColor(themeModel.placeholder))
                                    .keyboardType(.numberPad)
                                    .padding(.vertical, 12)
                                    .foregroundColor(themeModel.textPrimary)
                                
                                Divider().background(themeModel.divider)
                                
                                TextField("", text: $licensePlate, prompt: Text("License Plate").foregroundColor(themeModel.placeholder))
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
                                TextField("", text: $tankCapacity, prompt: Text("Tank Capacity (L)").foregroundColor(themeModel.placeholder))
                                    .keyboardType(.decimalPad)
                                    .padding(.vertical, 12)
                                    .foregroundColor(themeModel.textPrimary)
                                
                                Divider().background(themeModel.divider)
                                
                                TextField("", text: $mileage, prompt: Text("Mileage (km/l)").foregroundColor(themeModel.placeholder))
                                    .keyboardType(.decimalPad)
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
                    }
                    .padding(.vertical, themeModel.spacingMD)
                }
            }
            .navigationTitle("Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeModel.accent)
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
                    .foregroundColor(themeModel.accent)
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
                                .font(themeModel.bodyMedium())
                                .foregroundColor(.white)
                        }
                        .padding(32)
                        .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                    }
                }
            }
        }
    }
}

#Preview {
    AddVehicleView(viewModel: VehiclesViewModel())
}

