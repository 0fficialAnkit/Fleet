import SwiftUI

struct OrderDetailView: View {
    let trip: Trip
    let viewModel: OrdersViewModel
    @Environment(\.dismiss) private var dismiss
    
    var route: Route? {
        viewModel.route(for: trip.routeId)
    }
    
    var driverName: String {
        viewModel.driverName(for: trip.driverId)
    }
    
    var vehicleInfo: String {
        viewModel.vehicleName(for: trip.vehicleId)
    }
    
    var formattedDate: String {
        guard let date = trip.startTime else { return "Not Scheduled" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var orderIcon: String {
        switch trip.orderType {
        case .bulkOrderShip: return "shippingbox.fill"
        case .pickUpAndDrop: return "arrow.left.arrow.right"
        case .travel: return "car.fill"
        case .none: return "shippingbox"
        }
    }
    
    var orderColor: Color {
        switch trip.orderType {
        case .bulkOrderShip: return themeModel.maintenancePrimary
        case .pickUpAndDrop: return themeModel.accent
        case .travel: return themeModel.success
        case .none: return themeModel.textTertiary
        }
    }
    
    var body: some View {
        ZStack {
            themeModel.backgroundPrimary.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: themeModel.spacingLG) {
                    // Header Section
                    VStack(spacing: themeModel.spacingSM) {
                        ZStack {
                            Circle()
                                .fill(orderColor.opacity(0.15))
                                .frame(width: 110, height: 110)
                            
                            Image(systemName: orderIcon)
                                .font(.system(size: 44))
                                .foregroundColor(orderColor)
                        }
                        .padding(.bottom, 8)
                        
                        Text(route?.routeName ?? "Unknown Route")
                            .font(themeModel.largeTitle(24))
                            .foregroundColor(themeModel.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, themeModel.spacingMD)
                        
                        StatusBadge(text: trip.status?.rawValue.capitalized ?? "Unknown", color: viewModel.getStatusColor(for: trip.status))
                    }
                    .padding(.top, themeModel.spacingXL)
                    
                    // Information Cards
                    VStack(spacing: themeModel.spacingMD) {
                        OrderDetailInfoRow(icon: "number", title: "Order ID", value: "#\(trip.id.uuidString.prefix(8).uppercased())")
                        
                        Divider().background(themeModel.divider)
                        OrderDetailInfoRow(icon: "shippingbox.fill", title: "Order Type", value: trip.orderType?.rawValue ?? "N/A")
                        
                        Divider().background(themeModel.divider)
                        OrderDetailInfoRow(icon: "mappin.and.ellipse", title: "Destination", value: route?.endLocation ?? "N/A")
                        
                        Divider().background(themeModel.divider)
                        OrderDetailInfoRow(icon: "calendar", title: "Start Date", value: formattedDate)
                        
                        Divider().background(themeModel.divider)
                        OrderDetailInfoRow(icon: "person.crop.circle.fill", title: "Driver", value: driverName)
                        
                        Divider().background(themeModel.divider)
                        OrderDetailInfoRow(icon: "car.fill", title: "Vehicle", value: vehicleInfo)
                    }
                    .padding(themeModel.spacingMD)
                    .background(themeModel.backgroundElevated)
                    .cornerRadius(themeModel.radiusLG)
                    .padding(.horizontal, themeModel.spacingMD)
                }
            }
        }
        .navigationTitle("Order Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive, action: {
                        viewModel.deleteTrip(trip)
                        dismiss()
                    }) {
                        Label("Delete Order", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(themeModel.textPrimary)
                        .padding(8)
                }
            }
        }
    }
}

struct OrderDetailInfoRow: View {
    let icon: String
    let title: String
    let value: String
    var valueColor: Color = themeModel.textPrimary
    
    var body: some View {
        HStack(spacing: themeModel.spacingMD) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(themeModel.textTertiary)
                .frame(width: 24)
            
            Text(title)
                .font(themeModel.bodyMedium(16))
                .foregroundColor(themeModel.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(themeModel.body(16))
                .foregroundColor(valueColor)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        OrderDetailView(trip: MockData.trips.first!, viewModel: OrdersViewModel())
    }
}
