import SwiftUI

struct DriverSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    var orderType: OrderType
    var selectedVehicle: Vehicle
    var viewModel: OrdersViewModel
    @Binding var selectedOrderType: OrderType?
    
    // Fetch drivers from ViewModel data
    var availableDrivers: [Profile] {
        viewModel.driversWithRole()
    }
    
    // Map profile status to UI strings
    func driverStatusText(for status: String?) -> String {
        switch status {
        case "active": return "Available"
        case "suspended": return "Busy"
        case "inactive": return "Offline"
        default: return "Unknown"
        }
    }
    
    func driverStatusColor(for status: String?) -> Color {
        switch status {
        case "active": return Color.green
        case "suspended": return Color.yellow
        case "inactive": return Color(UIColor.quaternaryLabel)
        default: return Color(UIColor.quaternaryLabel)
        }
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    
                    if availableDrivers.isEmpty {
                        Text("No drivers found.")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(Color.secondary)
                            .padding(.top, 40)
                    } else {
                        ForEach(availableDrivers) { driver in
                            NavigationLink(destination: TripSchedulingView(
                                orderType: orderType,
                                selectedVehicle: selectedVehicle,
                                selectedDriver: driver,
                                viewModel: viewModel,
                                selectedOrderType: $selectedOrderType
                            )) {
                                HStack {
                                    HStack(spacing: 12) {
                                        Image(systemName: "person.crop.circle.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(Color.blue)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(driver.fullName)
                                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                                .foregroundColor(Color.primary)
                                            
                                            Text(driver.licenseNumber ?? "No License")
                                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                                .foregroundColor(Color.secondary)
                                        }
                                    }
                                    Spacer()
                                    
                                    StatusBadge(text: driverStatusText(for: driver.status), color: driverStatusColor(for: driver.status))
                                }
                                .contentShape(Rectangle())
                                .padding(16)
                                .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Select Driver")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        DriverSelectionView(
            orderType: .bulkOrderShip,
            selectedVehicle: Vehicle(
                id: UUID(),
                make: "Ford",
                model: "Transit",
                year: 2024,
                vin: "12345",
                licensePlate: "FL-99-TR",
                tankCapacity: 80.0,
                mileage: 12.4,
                purchaseDate: Date(),
                assignedDriverId: nil,
                status: .active
            ),
            viewModel: OrdersViewModel(),
            selectedOrderType: .constant(.bulkOrderShip)
        )
    }
}
