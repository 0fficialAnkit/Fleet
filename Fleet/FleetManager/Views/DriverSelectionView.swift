import SwiftUI

struct DriverSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    var orderType: OrderType
    var selectedVehicle: Vehicle
    var viewModel: OrdersViewModel
    @Binding var selectedOrderType: OrderType?
    
    // Fetch drivers from ViewModel data
    var availableDrivers: [User] {
        viewModel.driversWithRole()
    }
    
    // Map existing UserStatus to UI strings
    func driverStatusText(for status: UserStatus?) -> String {
        switch status {
        case .active: return "Available"
        case .suspended: return "Busy"
        case .inactive: return "Offline"
        case .none: return "Unknown"
        }
    }
    
    func driverStatusColor(for status: UserStatus?) -> Color {
        switch status {
        case .active: return themeModel.success
        case .suspended: return themeModel.warning
        case .inactive: return themeModel.textDisabled
        case .none: return themeModel.textDisabled
        }
    }
    
    var body: some View {
        ZStack {
            themeModel.backgroundPrimary.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: themeModel.spacingMD) {
                    
                    if availableDrivers.isEmpty {
                        Text("No drivers found.")
                            .font(themeModel.body(16))
                            .foregroundColor(themeModel.textSecondary)
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
                                            .foregroundColor(themeModel.accent)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(driver.fullName)
                                                .font(themeModel.headline(16))
                                                .foregroundColor(themeModel.textPrimary)
                                            
                                            Text(driver.licenseNumber ?? "No License")
                                                .font(themeModel.caption(14))
                                                .foregroundColor(themeModel.textSecondary)
                                        }
                                    }
                                    Spacer()
                                    
                                    StatusBadge(text: driverStatusText(for: driver.status), color: driverStatusColor(for: driver.status))
                                }
                                .contentShape(Rectangle())
                                .padding(themeModel.spacingMD)
                                .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                                )
                                .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, themeModel.spacingMD)
                    }
                }
                .padding(.vertical, themeModel.spacingMD)
            }
        }
        .navigationTitle("Select Driver")
        .navigationBarTitleDisplayMode(.inline)
    }
}
