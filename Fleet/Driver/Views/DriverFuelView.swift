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
                            Text("Fuel Volume (Liters)")
                                .font(themeModel.bodyMedium())
                                .foregroundStyle(themeModel.textSecondary)
                            TextField("0.0", text: $volume)
                                .keyboardType(.decimalPad)
                                .padding(themeModel.spacingMD)
                                .background(themeModel.inputBackground)
                                .cornerRadius(themeModel.radiusSM)
                        }
                        
                        VStack(alignment: .leading, spacing: themeModel.spacingSM) {
                            Text("Total Price Paid")
                                .font(themeModel.bodyMedium())
                                .foregroundStyle(themeModel.textSecondary)
                            TextField("0.00", text: $price)
                                .keyboardType(.decimalPad)
                                .padding(themeModel.spacingMD)
                                .background(themeModel.inputBackground)
                                .cornerRadius(themeModel.radiusSM)
                        }
                        
                        // Mock Auto-captured Location
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundStyle(themeModel.info)
                            Text("Current Location: Downtown Station")
                                .font(themeModel.caption())
                                .foregroundStyle(themeModel.textTertiary)
                        }
                        
                        Button(action: submitFuelLog) {
                            Text("Submit")
                                .font(themeModel.bodyMedium())
                                .frame(maxWidth: .infinity)
                                .padding(themeModel.spacingMD)
                                .background(volume.isEmpty || price.isEmpty ? themeModel.buttonDisabled : themeModel.buttonPrimary)
                                .foregroundColor(volume.isEmpty || price.isEmpty ? themeModel.buttonDisabledText : themeModel.buttonPrimaryText)
                                .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusSM))
                        }
                        .disabled(volume.isEmpty || price.isEmpty)
                    }
                    .padding(themeModel.spacingMD)
                    .background(themeModel.backgroundElevated)
                    .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusLG))
                    
                    if showSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(themeModel.success)
                            Text("Synced with Fleet Manager")
                                .font(themeModel.bodyMedium())
                                .foregroundStyle(themeModel.textPrimary)
                        }
                        .padding(themeModel.spacingMD)
                        .frame(maxWidth: .infinity)
                        .background(themeModel.success.opacity(0.15))
                        .cornerRadius(themeModel.radiusSM)
                    }
                    
                    // History Section
                    VStack(alignment: .leading, spacing: themeModel.spacingMD) {
                        Text("Recent Logs")
                            .font(themeModel.headline())
                            .foregroundStyle(themeModel.textPrimary)
                        
                        ForEach(viewModel.fuelLogs) { log in
                            HStack {
                                VStack(alignment: .leading, spacing: themeModel.spacingXS) {
                                    Text("\(String(format: "%.1f", log.litersUsed ?? 0.0)) Liters")
                                        .font(themeModel.headline())
                                        .foregroundColor(themeModel.success)
                                    Text((log.recordedAt ?? Date()).formatted(date: .abbreviated, time: .shortened))
                                        .font(themeModel.caption())
                                        .foregroundColor(themeModel.textSecondary)
                                }
                                
                                Spacer()
                                
                                Text("₹\(Int(log.fuelCost ?? 0.0))")
                                    .font(themeModel.headline())
                                    .foregroundColor(themeModel.textPrimary)
                            }
                            .padding(themeModel.spacingMD)
                            .background(themeModel.backgroundElevated)
                            .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusMD))
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
