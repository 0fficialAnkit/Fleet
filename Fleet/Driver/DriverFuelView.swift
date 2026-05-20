import SwiftUI

struct DriverFuelView: View {

    @State private var volume: String = ""
    @State private var price: String = ""
    @State private var showSuccess: Bool = false
    
    @StateObject private var dataStore = DataStore.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Input Form
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Log Fuel Expense")
                            .font(.title2.bold())
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Fuel Volume (Liters)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            TextField("0.0", text: $volume)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Total Price Paid")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            TextField("0.00", text: $price)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                        }
                        
                        // Mock Auto-captured Location
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                            Text("Current Location: Downtown Station")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Button(action: submitFuelLog) {
                            Text("Submit")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(volume.isEmpty || price.isEmpty ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(volume.isEmpty || price.isEmpty)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    if showSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Synced with Fleet Manager")
                                .font(.subheadline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(12)
                    }
                    
                    // History Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Logs")
                            .font(.headline)
                        
                        ForEach(dataStore.fuelLogs) { log in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(String(format: "%.1f", log.litersUsed ?? 0.0)) Liters")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                    Text((log.recordedAt ?? Date()).formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Text("₹\(Int(log.fuelCost ?? 0.0))")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("Fuel")
        }
    }
    
    private func submitFuelLog() {
        let liters = Double(volume) ?? 0.0
        let cost = Double(price) ?? 0.0
        let newLog = FuelLog(
            id: UUID(),
            vehicleId: dataStore.vehicle.id,
            driverId: nil,
            litersUsed: liters,
            fuelCost: cost,
            recordedAt: Date()
        )
        dataStore.fuelLogs.insert(newLog, at: 0)
        
        // Clear form
        volume = ""
        price = ""
        
        showSuccess = true
    }
}

#Preview {
    DriverFuelView()
}
