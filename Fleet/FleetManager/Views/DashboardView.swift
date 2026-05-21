import SwiftUI

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: themeModel.spacingLG) {
                        metricsGrid
                        recentOrdersSection
                        maintenanceSection
                    }
                    .padding(.vertical, themeModel.spacingMD)
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {

                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(themeModel.textPrimary)
                            .frame(width: 38, height: 38)
                            .background(themeModel.surfaceTertiary)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Metrics Grid
    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: themeModel.spacingMD) {
            MetricCardView(title: "Total Vehicles", value: "\(viewModel.totalVehicles)", icon: "car.2.fill", color: themeModel.info)
            MetricCardView(title: "Active Trips", value: "\(viewModel.activeTrips)", icon: "map.fill", color: themeModel.success)
            MetricCardView(title: "Pending Orders", value: "\(viewModel.pendingOrders)", icon: "doc.text.fill", color: themeModel.warning)
            MetricCardView(title: "Drivers on Trip", value: "\(viewModel.driversOnTrip)", icon: "person.2.fill", color: themeModel.analyticsPurple)
        }
        .padding(.horizontal, themeModel.spacingMD)
    }
    
    // MARK: - Recent Orders
    private var recentOrdersSection: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
            HStack {
                Text("Recent Orders")
                    .font(themeModel.title(22))
                    .foregroundColor(themeModel.textPrimary)
                Spacer()
                Button("See All") { }
                    .font(themeModel.bodyMedium())
                    .foregroundColor(themeModel.info)
            }
            .padding(.horizontal, themeModel.spacingMD)
            
            ForEach(viewModel.recentOrders) { trip in
                TripCardView(trip: trip)
                    .padding(.horizontal, themeModel.spacingMD)
            }
        }
    }
    
    // MARK: - Maintenance
    private var maintenanceSection: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
            Text("Need Maintenance")
                .font(themeModel.title(22))
                .foregroundColor(themeModel.textPrimary)
                .padding(.horizontal, themeModel.spacingMD)
            
            ForEach(viewModel.maintenanceVehicles) { vehicle in
                MaintenanceCardView(vehicle: vehicle)
                    .padding(.horizontal, themeModel.spacingMD)
            }
        }
    }
}

// MARK: - Supporting Views

struct MetricCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingSM) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .padding(10)
                    .background(color.opacity(0.15))
                    .cornerRadius(themeModel.radiusSM)
                Spacer()
            }
            
            Text(value)
                .font(themeModel.largeTitle(28))
                .foregroundColor(themeModel.textPrimary)
            
            Text(title)
                .font(themeModel.bodyMedium(14))
                .foregroundColor(themeModel.textSecondary)
        }
        .padding(themeModel.spacingMD)
        .background(themeModel.backgroundElevated)
        .cornerRadius(themeModel.radiusLG)
        .shadow(color: themeModel.shadowSoft, radius: 5, x: 0, y: 2)
    }
}

struct TripCardView: View {
    let trip: Trip
    
    var routeName: String {
        MockData.routes.first(where: { $0.id == trip.routeId })?.routeName ?? "Unknown Route"
    }
    
    var driverName: String {
        MockData.users.first(where: { $0.id == trip.driverId })?.fullName ?? "Unassigned"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
            HStack {
                Text(routeName)
                    .font(themeModel.headline(16))
                    .foregroundColor(themeModel.textPrimary)
                    .lineLimit(1)
                Spacer()
                statusBadge(for: trip.status ?? .scheduled)
            }
            
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .foregroundColor(themeModel.textTertiary)
                        .font(.system(size: 14))
                    Text(driverName)
                        .font(themeModel.caption(14))
                        .foregroundColor(themeModel.textSecondary)
                }
                Spacer()
                if let distance = trip.distance {
                    HStack(spacing: 6) {
                        Image(systemName: "ruler.fill")
                            .foregroundColor(themeModel.textTertiary)
                            .font(.system(size: 14))
                        Text(String(format: "%.1f km", distance))
                            .font(themeModel.caption(14))
                            .foregroundColor(themeModel.textSecondary)
                    }
                }
            }
        }
        .padding(themeModel.spacingMD)
        .background(themeModel.backgroundElevated)
        .cornerRadius(themeModel.radiusLG)
    }
    
    @ViewBuilder
    private func statusBadge(for status: TripStatus) -> some View {
        let color: Color = {
            switch status {
            case .scheduled: return themeModel.info
            case .active: return themeModel.warning
            case .completed: return themeModel.success
            case .cancelled: return themeModel.danger
            }
        }()
        
        Text(status.rawValue.capitalized)
            .font(themeModel.small(12))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(themeModel.radiusXS)
    }
}

struct MaintenanceCardView: View {
    let vehicle: Vehicle
    
    var maintenanceTask: MaintenanceTask? {
        MockData.maintenanceTasks.first(where: { $0.vehicleId == vehicle.id && $0.status != .completed })
    }
    
    var body: some View {
        HStack(spacing: themeModel.spacingMD) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 24))
                .foregroundColor(themeModel.warning)
                .padding(12)
                .background(themeModel.warning.opacity(0.15))
                .cornerRadius(themeModel.radiusSM)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(vehicle.make ?? "") \(vehicle.model ?? "")")
                    .font(themeModel.headline(16))
                    .foregroundColor(themeModel.textPrimary)
                
                Text(vehicle.licensePlate ?? "No Plate")
                    .font(themeModel.bodyMedium(14))
                    .foregroundColor(themeModel.textSecondary)
                
                if let task = maintenanceTask {
                    Text(task.description ?? "Needs maintenance")
                        .font(themeModel.caption(12))
                        .foregroundColor(themeModel.danger)
                        .lineLimit(2)
                }
            }
            Spacer()
        }
        .padding(themeModel.spacingMD)
        .background(themeModel.backgroundElevated)
        .cornerRadius(themeModel.radiusLG)
    }
}

#Preview {
    DashboardView()
}
