import SwiftUI

struct DriverFuelView: View {

    @State private var volume: String = ""
    @State private var price: String = ""
    @State private var showSuccess: Bool = false
    
    @State private var viewModel = DriverFuelViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Input Form
                    
                        VStack(alignment: .leading, spacing: themeModel.spacingLG) {
                            Text("Log Fuel Expense")
                                .font(themeModel.title(22))
                                .foregroundStyle(themeModel.textPrimary)
                            
                            VStack(alignment: .leading, spacing: themeModel.spacingSM) {
                                HStack {
                                    Image(systemName: "drop.fill")
                                        .foregroundStyle(themeModel.textSecondary)
                                    Text("Fuel Volume (Liters)")
                                        .font(themeModel.bodyMedium())
                                        .foregroundStyle(themeModel.textSecondary)
                                }
                                TextField("0.0", text: $volume)
                                    .keyboardType(.decimalPad)
                                    .padding(themeModel.spacingMD)
                                    .background(themeModel.inputBackground)
                                    .cornerRadius(themeModel.radiusSM)
                            }
                            
                            VStack(alignment: .leading, spacing: themeModel.spacingSM) {
                                HStack {
                                    Image(systemName: "indianrupeesign")
                                        .foregroundStyle(themeModel.textSecondary)
                                    Text("Total Price Paid")
                                        .font(themeModel.bodyMedium())
                                        .foregroundStyle(themeModel.textSecondary)
                                }
                                TextField("0.00", text: $price)
                                    .keyboardType(.decimalPad)
                                    .padding(themeModel.spacingMD)
                                    .background(themeModel.inputBackground)
                                    .cornerRadius(themeModel.radiusSM)
                            }
                            
                            // Mock Auto-captured Location
                            HStack {
                                Image(systemName: "location.fill.viewfinder")
                                    .foregroundStyle(themeModel.driverPrimary)
                                Text("Current Location: Downtown Station")
                                    .font(themeModel.caption())
                                    .foregroundStyle(themeModel.textTertiary)
                            }
                            
                            Button(action: submitFuelLog) {
                                HStack {
                                    Image(systemName: "arrow.up.doc")
                                    Text("Submit")
                                }
                                    .font(themeModel.bodyMedium())
                                    .frame(maxWidth: .infinity)
                                    .padding(themeModel.spacingMD)
                                    .background(volume.isEmpty || price.isEmpty ? themeModel.buttonDisabled : themeModel.driverPrimary)
                                    .foregroundColor(volume.isEmpty || price.isEmpty ? themeModel.buttonDisabledText : themeModel.buttonPrimaryText)
                                    .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusSM))
                            }
                            .disabled(volume.isEmpty || price.isEmpty)
                        }
                        .padding(themeModel.spacingMD)
                        .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                        )
                        .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
                    
                    if showSuccess {
                        
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(themeModel.success)
                                Text("Synced with Fleet Manager")
                                    .font(themeModel.bodyMedium())
                                    .foregroundStyle(themeModel.textPrimary)
                                Spacer()
                            }
                            .padding(themeModel.spacingMD)
                            .background(themeModel.success.opacity(0.15))
                            .padding(0)
                            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                            )
                            .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
                    }
                    
                    // History Section
                    VStack(alignment: .leading, spacing: themeModel.spacingMD) {
                        SectionHeader(title: "Recent Logs")
                        
                        ForEach(viewModel.fuelLogs) { log in
                            
                                HStack {
                                    VStack(alignment: .leading, spacing: themeModel.spacingXS) {
                                        HStack {
                                            Image(systemName: "drop.fill")
                                                .foregroundColor(themeModel.success)
                                            Text("\(String(format: "%.1f", log.litersUsed ?? 0.0)) Liters")
                                                .font(themeModel.headline())
                                                .foregroundColor(themeModel.textPrimary)
                                        }
                                        HStack {
                                            Image(systemName: "calendar")
                                                .foregroundColor(themeModel.textSecondary)
                                            Text((log.recordedAt ?? Date()).formatted(date: .abbreviated, time: .shortened))
                                                .font(themeModel.caption())
                                                .foregroundColor(themeModel.textSecondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 2) {
                                        Image(systemName: "indianrupeesign")
                                            .foregroundColor(themeModel.textSecondary)
                                        Text("\(Int(log.fuelCost ?? 0.0))")
                                            .font(themeModel.title(22))
                                            .foregroundColor(themeModel.textPrimary)
                                    }
                                }
                                .padding(themeModel.spacingMD)
                                .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                                )
                                .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
                        }
                    }
                }
                .padding()
            }
            .background(themeModel.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Fuel")
        }
    }
    
    private func submitFuelLog() {
        let liters = Double(volume) ?? 0.0
        let cost = Double(price) ?? 0.0
        let vehicleId = MockData.vehicles.first?.id ?? UUID()
        
        viewModel.addFuelLog(liters: liters, cost: cost, vehicleId: vehicleId)
        
        // Clear form
        volume = ""
        price = ""
        
        showSuccess = true
    }
}

#Preview {
    DriverFuelView()
}
