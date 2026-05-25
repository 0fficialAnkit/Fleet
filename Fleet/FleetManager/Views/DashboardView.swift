import SwiftUI

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @State private var isShowingProfile = false
    @State private var showingNotifications = false
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.vehicles.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: themeModel.spacingLG) {
                            fleetOverviewCard
                            recentOrdersSection
                            maintenanceSection
                        }
                        .padding(.bottom, themeModel.spacingXL)
                    }
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button(action: { showingNotifications = true }) {
                        Image(systemName: "bell")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(themeModel.textPrimary)
                            .frame(width: 38, height: 38)
                    }
                    
                    Button(action: { isShowingProfile = true }) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(themeModel.accent)
                    }
                }
            }
            .sheet(isPresented: $isShowingProfile) {
                ProfileView()
                    .environment(authViewModel)
            }
            .sheet(isPresented: $showingNotifications) {
                NotificationsView()
            }
            .navigationDestination(for: DashboardDestination.self) { destination in
                switch destination {
                case .vehiclesRoot:
                    VehiclesRootView()
                default:
                    EmptyView()
                }
            }
        }
        .task {
            await viewModel.loadData()
            viewModel.setupRealtime()
        }
    }
    
    // MARK: - Fleet Overview Card (Idea 3)
    
    private var fleetOverviewCard: some View {
        NavigationLink(value: DashboardDestination.vehiclesRoot) {
            VStack(spacing: 0) {
                // Header: icon badge + count + chevron on top trailing
                HStack(alignment: .top, spacing: themeModel.spacingMD) {
                    ZStack {
                        RoundedRectangle(cornerRadius: themeModel.radiusSM, style: .continuous)
                            .fill(themeModel.accent.opacity(0.12))
                            .frame(width: 48, height: 48)
                        Image(systemName: "truck.box.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(themeModel.accent)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total Vehicle \(viewModel.totalVehicles)")
                            .font(themeModel.title(26))
                            .foregroundStyle(themeModel.textPrimary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(themeModel.textSecondary)
                        .padding(.top, 4)
                }
                
                Divider()
                    .background(themeModel.divider)
                    .padding(.vertical, themeModel.spacingMD)
                
                // Status breakdown row
                HStack(spacing: themeModel.spacingSM) {
                    FleetStatPill(
                        value: viewModel.driversOnTrip,
                        label: "Active",
                        color: themeModel.success
                    )
                    FleetStatPill(
                        value: max(0, viewModel.totalVehicles - viewModel.driversOnTrip - viewModel.maintenanceVehicles.count),
                        label: "Idle",
                        color: themeModel.warning
                    )
                    FleetStatPill(
                        value: viewModel.maintenanceVehicles.count,
                        label: "Service",
                        color: themeModel.danger
                    )
                }
            }
            .padding(themeModel.spacingMD)
            .background(themeModel.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                    .stroke(themeModel.border.opacity(0.6), lineWidth: 0.5)
            )
            .shadow(color: themeModel.shadowSoft, radius: 12, y: 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, themeModel.spacingMD)
    }
    
    // MARK: - Recent Orders
    
    private var recentOrdersSection: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
            SectionHeader(title: "Recent Orders", action: "See All") {
                // Action
            }
            .padding(.horizontal, themeModel.spacingMD)
            
            if viewModel.recentOrders.isEmpty {
                Text("No orders yet.")
                    .font(themeModel.body(16))
                    .foregroundStyle(themeModel.textSecondary)
                    .padding(.horizontal, themeModel.spacingMD)
            } else {
                ForEach(viewModel.recentOrders) { trip in
                    TripCardView(trip: trip, viewModel: viewModel)
                        .padding(.horizontal, themeModel.spacingMD)
                }
            }
        }
    }
    
    // MARK: - Maintenance
    
    private var maintenanceSection: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
            SectionHeader(title: "Need Maintenance")
                .padding(.horizontal, themeModel.spacingMD)
            
            if viewModel.maintenanceVehicles.isEmpty {
                Text("All vehicles operational.")
                    .font(themeModel.body(16))
                    .foregroundStyle(themeModel.textSecondary)
                    .padding(.horizontal, themeModel.spacingMD)
            } else {
                ForEach(viewModel.maintenanceVehicles) { vehicle in
                    MaintenanceCardView(vehicle: vehicle, viewModel: viewModel)
                        .padding(.horizontal, themeModel.spacingMD)
                }
            }
        }
    }
}

// MARK: - Fleet Stat Pill

struct FleetStatPill: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Text("\(value)")
                .font(themeModel.headline(20))
                .foregroundStyle(themeModel.textPrimary)
            Text(label)
                .font(themeModel.small(11))
                .foregroundStyle(themeModel.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, themeModel.spacingMD)
        .background(color.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous)
                .stroke(color.opacity(0.25), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous))
    }
}

// MARK: - Trip Card

struct TripCardView: View {
    let trip: Trip
    let viewModel: DashboardViewModel
    
    var routeName: String {
        viewModel.routeName(for: trip.routeId)
    }
    
    var displayTitle: String {
        if let type = trip.orderType {
            return type.displayName
        }
        return routeName
    }
    
    var driverName: String {
        viewModel.driverName(for: trip.driverId)
    }
    
    var statusColor: Color {
        switch trip.status {
        case .scheduled: return themeModel.info
        case .active:    return themeModel.warning
        case .completed: return themeModel.success
        case .cancelled: return themeModel.danger
        case .none:      return themeModel.textDisabled
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
            HStack {
                Text(displayTitle)
                    .font(themeModel.headline(16))
                    .foregroundStyle(themeModel.textPrimary)
                    .lineLimit(1)
                Spacer()
                StatusBadge(text: trip.status?.rawValue.capitalized ?? "Unknown", color: statusColor)
            }
            
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.fill")
                        .foregroundStyle(themeModel.accent)
                        .font(.system(size: 16))
                    Text(driverName)
                        .font(themeModel.caption(14))
                        .foregroundStyle(themeModel.textSecondary)
                }
                Spacer()
                if let distance = trip.distance {
                    HStack(spacing: 6) {
                        Image(systemName: "ruler.fill")
                            .foregroundStyle(themeModel.textTertiary)
                            .font(.system(size: 14))
                        Text(String(format: "%.1f km", distance))
                            .font(themeModel.caption(14))
                            .foregroundStyle(themeModel.textSecondary)
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

// MARK: - Maintenance Card

struct MaintenanceCardView: View {
    let vehicle: Vehicle
    let viewModel: DashboardViewModel
    
    var maintenanceTask: MaintenanceTask? {
        viewModel.maintenanceTask(for: vehicle.id)
    }
    
    var body: some View {
        HStack(spacing: themeModel.spacingMD) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 24))
                .foregroundStyle(themeModel.warning)
                .frame(width: 44, height: 44)
                .background(themeModel.warning.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusSM, style: .continuous))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(vehicle.make ?? "") \(vehicle.model ?? "")")
                    .font(themeModel.headline(16))
                    .foregroundStyle(themeModel.textPrimary)
                
                Text(vehicle.licensePlate ?? "No Plate")
                    .font(themeModel.bodyMedium(14))
                    .foregroundStyle(themeModel.textSecondary)
                
                if let task = maintenanceTask {
                    Text(task.description ?? "Needs maintenance")
                        .font(themeModel.caption(12))
                        .foregroundStyle(themeModel.danger)
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

