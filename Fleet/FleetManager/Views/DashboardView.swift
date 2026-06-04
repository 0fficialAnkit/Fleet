import SwiftUI
internal import Auth

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @State private var isShowingProfile = false
    @State private var showingNotifications = false
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if viewModel.isLoading && viewModel.vehicles.isEmpty {
                    ProgressView()
                        .tint(.white)
                } else {
                    List {
                        Section {
                            fleetOverviewCard
                        }
                        
                        Section {
                            MiniFuelDashboardCard(adminId: viewModel.adminId)
                        }

                        liveFleetSection

                        liveDriverAlertsSection

                        maintenanceSection
                    }
                    .refreshable { await viewModel.loadData() }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button(action: { showingNotifications = true }) {
                        Image(systemName: viewModel.hasUnreadNotifications ? "bell.badge" : "bell")
                            .font(.system(size: 17, weight: .medium))
                            //.symbolRenderingMode(viewModel.hasUnreadNotifications ? .multicolor : .monochrome)
                            .foregroundStyle(.primary)
                            .frame(width: 38, height: 38)
                    }

                    Button(action: { isShowingProfile = true }) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(Color.teal)
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
                case .orderDetail(let trip):
                    OrderDetailView(
                        trip: trip,
                        viewModel: OrdersViewModel(
                            trips: viewModel.trips,
                            routes: viewModel.routes,
                            profiles: viewModel.profiles,
                            vehicles: viewModel.vehicles
                        )
                    )
                case .allMaintenanceAlerts:
                    AllMaintenanceAlertsView(
                        alerts: viewModel.predictiveAlerts,
                        maintenanceStaff: viewModel.profiles.filter { $0.role == "maintenance" }
                    )
                case .fuelAnalytics:
                    FleetFuelAnalyticsView(adminId: viewModel.adminId)
                }
            }
        }
        .task {
            // adminId is set via onChange below on first appear
        }
        .onChange(of: authViewModel.currentUser?.id, initial: true) { _, _ in
            guard let adminId = authViewModel.currentUserId else { return }
            viewModel.adminId = adminId
            Task {
                await viewModel.loadData()
                viewModel.setupRealtime()
            }
        }
    }


    // MARK: - Fleet Overview Card (Idea 3)

    private var fleetOverviewCard: some View {
        ZStack {
            NavigationLink(value: DashboardDestination.vehiclesRoot) {
                EmptyView()
            }
            .opacity(0)

            VStack(spacing: 0) {
                // Header: icon badge + count + chevron on top trailing
                HStack(alignment: .top, spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.teal.opacity(0.12))
                            .frame(width: 48, height: 48)
                        Image(systemName: "truck.box.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(Color.teal)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total Vehicle \(viewModel.totalVehicles)")
                            .font(.title2.bold())
                            .foregroundStyle(Color.primary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(.tertiaryLabel))
                        .padding(.top, 4)
                }

                Divider()
                    .background(Color(.separator))
                    .padding(.vertical, 16)

                // Status breakdown row
                HStack(spacing: 8) {
                    FleetStatPill(
                        value: viewModel.driversOnTrip,
                        label: "Active",
                        color: Color.green
                    )
                    FleetStatPill(
                        value: max(0, viewModel.totalVehicles - viewModel.driversOnTrip - viewModel.inServiceVehicles),
                        label: "Idle",
                        color: Color.orange
                    )
                    FleetStatPill(
                        value: viewModel.inServiceVehicles,
                        label: "Service",
                        color: Color.red
                    )
                }
            }
            .padding(.vertical, 4)
        }
    }


    // MARK: - Live Fleet Map

    private var liveFleetSection: some View {
        let activeTrips = viewModel.trips.filter { $0.status == .active }
        return Section(header: HStack {
            Text("Live Fleet")
            Spacer()
            if !activeTrips.isEmpty {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 7, height: 7)
                    Text("\(activeTrips.count) on route")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Color.secondary)
                        .textCase(.none)
                }
            }
        }) {
            DashboardMapView(
                activeTrips: activeTrips,
                routes: viewModel.routes,
                profiles: viewModel.profiles,
                vehicleLocations: viewModel.vehicleLocations
            )
            .frame(height: 250)
            .listRowInsets(EdgeInsets())

            if !activeTrips.isEmpty {
                ForEach(activeTrips) { trip in
                    let route = viewModel.routes.first { $0.id == trip.routeId }
                    let driverName = viewModel.driverName(for: trip.driverId)
                    HStack(spacing: 10) {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundStyle(Color.teal)
                            .font(.system(size: 16))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(driverName)
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.primary)
                            if let start = route?.startLocation, let end = route?.endLocation {
                                Text("\(start) → \(end)")
                                    .font(.caption)
                                    .foregroundStyle(Color.secondary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        StatusBadge(text: "Active", color: .green)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Maintenance

    private var maintenanceSection: some View {
        let topAlerts = Array(viewModel.predictiveAlerts.prefix(3))
        return Section {
            if viewModel.predictiveAlerts.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("All vehicles operational")
                            .font(.body.bold())
                            .foregroundStyle(Color.primary)
                        Text("No maintenance alerts detected")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                }
                .padding(.vertical, 6)
            } else {
                ForEach(topAlerts) { alert in
                    PredictiveAlertCardView(
                        alert: alert,
                        maintenanceStaff: viewModel.profiles.filter { $0.role == "maintenance" }
                    )
                }
            }
        } header: {
            HStack {
                Text("Need Maintenance")
                Spacer()
                if viewModel.predictiveAlerts.count > 3 {
                    NavigationLink(value: DashboardDestination.allMaintenanceAlerts) {
                        HStack(spacing: 4) {
                            Text("See All (\(viewModel.predictiveAlerts.count))")
                                .font(.caption.weight(.medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(Color.orange)
                        .textCase(.none)
                    }
                } else if !viewModel.predictiveAlerts.isEmpty {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                }
            }
        }
    }

    // MARK: - Live Driver Alerts Section

    private var liveDriverAlertsSection: some View {
        let incidents = viewModel.recentVoiceIncidents
        return Section {
            if incidents.isEmpty {
                Label("No driver alerts", systemImage: "checkmark.shield.fill")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(incidents) { incident in
                    Group {
                        if let trip = viewModel.trips.first(where: { $0.id == incident.tripId }) {
                            NavigationLink(value: DashboardDestination.orderDetail(trip)) {
                                incidentRow(incident)
                            }
                        } else {
                            incidentRow(incident)
                        }
                    }
                }
            }
        } header: {
            HStack {
                Text("Live Driver Alerts")
                if !incidents.isEmpty {
                    Text("\(incidents.count)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private func incidentRow(_ incident: TripIncident) -> some View {
        let trip = viewModel.trips.first(where: { $0.id == incident.tripId })
        let driverName = viewModel.driverName(for: incident.driverId ?? trip?.driverId)
        let vehicleName = viewModel.vehicleName(for: trip?.vehicleId)

        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: incidentIcon(incident.incidentType))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(incidentColor(incident.incidentType))
                .frame(width: 32, height: 32)
                .background(incidentColor(incident.incidentType).opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(incident.incidentType)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    if let date = incident.createdAt {
                        Text(date.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(incident.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Label(driverName, systemImage: "person.fill")
                    Text("•")
                    Label(vehicleName, systemImage: "truck.box.fill")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.secondary)
                .padding(.top, 2)

                if !incident.location.isEmpty && incident.location != "Unknown Location" {
                    Label(incident.location, systemImage: "mappin")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func incidentIcon(_ type: String) -> String {
        switch type {
        case "Breakdown": return "wrench.and.screwdriver.fill"
        case "Traffic":   return "car.2.fill"
        case "Accident":  return "car.burst.fill"
        case "Weather":   return "cloud.heavyrain.fill"
        default:          return "exclamationmark.triangle.fill"
        }
    }

    private func incidentColor(_ type: String) -> Color {
        switch type {
        case "Breakdown": return .red
        case "Traffic":   return .orange
        case "Accident":  return .red
        case "Weather":   return .blue
        default:          return .orange
        }
    }
}

// MARK: - Fleet Stat Pill

struct FleetStatPill: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(uiColor: .tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
        case .scheduled: return Color.blue
        case .active:    return Color.green
        case .completed: return Color.green
        case .cancelled: return Color.red
        case .none:      return Color(.quaternaryLabel)
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(displayTitle)
                        .font(.body.bold())
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)
                    Spacer()
                    StatusBadge(text: trip.status?.rawValue.capitalized ?? "Unknown", color: statusColor)
                }

                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundStyle(Color.teal)
                            .font(.system(size: 16))
                        Text(driverName)
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                    }
                    Spacer()
                    if let distance = trip.distance {
                        HStack(spacing: 6) {
                            Image(systemName: "ruler.fill")
                                .foregroundStyle(Color(.tertiaryLabel))
                                .font(.system(size: 14))
                            Text(String(format: "%.1f km", distance))
                                .font(.subheadline)
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }
            }

        }
        .padding(.vertical, 4)
    }
}

// MARK: - Predictive Alert Card

struct PredictiveAlertCardView: View {
    let alert: PredictiveMaintenanceAlert
    let maintenanceStaff: [Profile]
    @State private var showingAssignment = false

    private var accentColor: Color {
        alert.severity == .critical ? Color.red : Color.orange
    }

    private var severityLabel: String {
        alert.severity == .critical ? "Critical" : "Warning"
    }

    private var severityIcon: String {
        alert.severity == .critical ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill"
    }

    var body: some View {
        Button(action: { showingAssignment = true }) {
            VStack(alignment: .leading, spacing: 10) {
                // Header row
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(accentColor.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(accentColor)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(alert.vehicle.make ?? "") \(alert.vehicle.model ?? "")")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.primary)
                        Text(alert.vehicle.licensePlate ?? "No Plate")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }

                    Spacer()

                    // Severity badge
                    HStack(spacing: 4) {
                        Image(systemName: severityIcon)
                            .font(.system(size: 11, weight: .semibold))
                        Text(severityLabel)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(accentColor.opacity(0.1))
                    .clipShape(Capsule())
                }

                Divider()

                // Predicted issue
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.secondary)
                        .padding(.top, 1)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Predicted Issue")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                            .textCase(.uppercase)
                        Text(alert.reason)
                            .font(.subheadline)
                            .foregroundStyle(Color.primary)
                    }
                }

                // Recommended action
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.yellow)
                        .padding(.top, 1)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recommended Action")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                            .textCase(.uppercase)
                        Text(alert.recommendation)
                            .font(.subheadline)
                            .foregroundStyle(Color.primary)
                            .lineLimit(2)
                    }
                }

                // Assign row
                HStack {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.teal)
                    Text("Tap to assign to maintenance staff")
                        .font(.caption)
                        .foregroundStyle(Color.teal)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                }
                .padding(.top, 2)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingAssignment) {
            MaintenanceAssignmentSheet(
                vehicleName: "\(alert.vehicle.make ?? "") \(alert.vehicle.model ?? "")",
                licensePlate: alert.vehicle.licensePlate ?? "No Plate",
                severityLabel: severityLabel,
                severityColor: accentColor,
                severityIcon: severityIcon,
                issueTitle: "Predicted Issue",
                issueDescription: alert.reason,
                recommendationTitle: "Recommended Action",
                recommendationDescription: alert.recommendation,
                maintenanceStaff: maintenanceStaff
            ) { staffId, notes in
                // Create Work Order
                let workOrderId = try await WorkOrderService.createWorkOrder(
                    vehicleId: alert.vehicle.id,
                    createdBy: nil,
                    assignedTo: staffId,
                    priority: alert.severity == .critical ? .critical : .medium,
                    status: .open
                )
                
                let task = MaintenanceTask(
                    id: UUID(),
                    workOrderId: workOrderId,
                    vehicleId: alert.vehicle.id,
                    scheduledBy: nil,
                    assignedTo: staffId,
                    taskType: .inspection,
                    description: "\(alert.reason). \(alert.recommendation)\(notes.isEmpty ? "" : "\nNotes: \(notes)")",
                    scheduledDate: Date(),
                    targetMileage: nil,
                    serviceIntervalMonths: nil,
                    scheduleType: .date,
                    status: .pending
                )
                try await MaintenanceTaskService.createTask(task)

                // Mark the vehicle as "in service" so the Service stat pill
                // updates immediately and the vehicle leaves the alert list.
                var updatedVehicle = alert.vehicle
                updatedVehicle.status = .maintenance
                try? await VehicleService.updateVehicle(updatedVehicle)
            }
        }
    }
}

// MARK: - All Maintenance Alerts View

struct AllMaintenanceAlertsView: View {
    let alerts: [PredictiveMaintenanceAlert]
    let maintenanceStaff: [Profile]

    var body: some View {
        List {
            ForEach(alerts) { alert in
                PredictiveAlertCardView(alert: alert, maintenanceStaff: maintenanceStaff)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("All Maintenance Alerts")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Mini Fuel Dashboard Card

struct MiniFuelDashboardCard: View {
    let adminId: UUID?
    @State private var viewModel = FleetFuelAnalyticsViewModel()

    var body: some View {
        ZStack {
            NavigationLink(value: DashboardDestination.fuelAnalytics) {
                EmptyView()
            }
            .opacity(0)

            VStack(spacing: 0) {
                // Header
                HStack(alignment: .top, spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.orange.opacity(0.12))
                            .frame(width: 48, height: 48)
                        Image(systemName: "drop.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(Color.orange)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Fuel Analytics")
                            .font(.title2.bold())
                            .foregroundStyle(Color.primary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(.tertiaryLabel))
                        .padding(.top, 4)
                }

                Divider()
                    .background(Color(.separator))
                    .padding(.vertical, 16)

                // Stats breakdown row
                HStack(spacing: 8) {
                    FuelStatPill(
                        value: String(format: "%.0f km", viewModel.totalDistance),
                        label: "Total Distance",
                        color: Color.blue
                    )
                    FuelStatPill(
                        value: String(format: "%.1f L", viewModel.totalLiters),
                        label: "Fuel Used",
                        color: Color.orange
                    )
                }
            }
            .padding(.vertical, 4)
        }
        .task {
            viewModel.adminId = adminId
            await viewModel.loadData()
        }
    }
}

struct FuelStatPill: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(uiColor: .tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    DashboardView()
        .environment(AuthViewModel())
}

