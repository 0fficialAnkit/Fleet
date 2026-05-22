import SwiftUI

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @State private var isShowingProfile = false
    @Environment(AuthViewModel.self) private var authViewModel

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
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button(action: {
                        // Notification action
                    }) {
                        Image(systemName: "bell.badge")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(themeModel.textPrimary)
                            .frame(width: 38, height: 38)
                    }

                    Button(action: { isShowingProfile = true }) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(themeModel.analyticsPurple)
                    }
                }
            }
            .sheet(isPresented: $isShowingProfile) {
                ProfileView()
                    .environment(authViewModel)
            }
        }
        .onAppear {
            viewModel.refreshData()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("VehiclesUpdated"))) { _ in
            viewModel.refreshData()
        }
    }

    
    // MARK: - Metrics Grid
    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: themeModel.spacingMD) {
            NavigationLink(destination: VehiclesRootView()) {
                MetricCard(icon: "truck.box.fill", value: "\(viewModel.totalVehicles)", label: "Total Vehicles", color: themeModel.accent)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            MetricCard(icon: "location.north.line.fill", value: "\(viewModel.activeTrips)", label: "Active Trips", color: themeModel.success)
            MetricCard(icon: "tray.full.fill", value: "\(viewModel.pendingOrders)", label: "Pending Orders", color: themeModel.warning)
            MetricCard(icon: "steeringwheel", value: "\(viewModel.driversOnTrip)", label: "Drivers on Trip", color: themeModel.analyticsPurple)
        }
        .padding(.horizontal, themeModel.spacingMD)
    }
    
    // MARK: - Recent Orders
    private var recentOrdersSection: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
            SectionHeader(title: "Recent Orders", action: "See All") {
                // Action
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
            SectionHeader(title: "Need Maintenance")
                .padding(.horizontal, themeModel.spacingMD)
            
            ForEach(viewModel.maintenanceVehicles) { vehicle in
                MaintenanceCardView(vehicle: vehicle)
                    .padding(.horizontal, themeModel.spacingMD)
            }
        }
    }
}

// MARK: - Supporting Views

struct TripCardView: View {
    let trip: Trip
    
    var routeName: String {
        MockData.routes.first(where: { $0.id == trip.routeId })?.routeName ?? "Unknown Route"
    }
    
    var driverName: String {
        MockData.users.first(where: { $0.id == trip.driverId })?.fullName ?? "Unassigned"
    }
    
    var statusColor: Color {
        switch trip.status {
        case .scheduled: return themeModel.info
        case .active: return themeModel.warning
        case .completed: return themeModel.success
        case .cancelled: return themeModel.danger
        case .none: return themeModel.textDisabled
        }
    }
    
    var body: some View {
        
            VStack(alignment: .leading, spacing: themeModel.spacingMD) {
                HStack {
                    Text(routeName)
                        .font(themeModel.headline(16))
                        .foregroundColor(themeModel.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    StatusBadge(text: trip.status?.rawValue.capitalized ?? "Unknown", color: statusColor)
                }
                
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundColor(themeModel.accent)
                            .font(.system(size: 16))
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
            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
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
                    .frame(width: 44, height: 44)
                    .background(themeModel.warning.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusSM, style: .continuous))
                
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
            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
    }
}

#Preview {
    DashboardView()
        .environment(AuthViewModel())
}
