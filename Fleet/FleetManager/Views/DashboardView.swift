import SwiftUI
internal import Auth

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @State private var isShowingProfile = false
    @State private var showingNotifications = false
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var navigationPath = NavigationPath()
    @State private var selectedAlertForAssignment: PredictiveMaintenanceAlert?

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if viewModel.isLoading && viewModel.vehicles.isEmpty {
                    ProgressView()
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

                        resolvedMaintenanceCostSection

                        predictiveMaintenanceSection
                    }
                    .refreshable { await viewModel.loadData() }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button(action: { showingNotifications = true }) {
                        Image(systemName: viewModel.hasUnreadNotifications ? "bell.badge" : "bell")
                            .font(.system(size: 17, weight: .medium))
                            //.symbolRenderingMode(viewModel.hasUnreadNotifications ? .multicolor : .monochrome)
                            .foregroundStyle(.primary)
                            .frame(width: 38, height: 38)
                    }
                    .buttonStyle(.plain)

                    Button(action: { isShowingProfile = true }) {
                        Image(systemName: "person.crop.circle")
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $isShowingProfile) {
                ProfileView()
                    .environment(authViewModel)
            }
            .sheet(isPresented: $showingNotifications) {
                NotificationsView()
            }
            .sheet(item: $selectedAlertForAssignment) { alert in
                MaintenanceAssignmentSheet(
                    vehicleName: "\(alert.vehicle.make ?? "") \(alert.vehicle.model ?? "")",
                    licensePlate: alert.vehicle.licensePlate ?? "No Plate",
                    severityLabel: alert.severity == .critical ? "Critical" : "Warning",
                    severityColor: alert.severity == .critical ? .red : .orange,
                    severityIcon: alert.severity == .critical ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill",
                    issueTitle: "Predicted Issue",
                    issueDescription: alert.reason,
                    recommendationTitle: "Recommended Action",
                    recommendationDescription: alert.recommendation,
                    maintenanceStaff: viewModel.profiles.filter { $0.role == "maintenance" }
                ) { staffId, notes in
                    let workOrderId = try await WorkOrderService.createWorkOrder(
                        vehicleId: alert.vehicle.id,
                        createdBy: nil,
                        assignedTo: staffId,
                        priority: alert.severity == .critical ? .high : .medium,
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
                    var updatedVehicle = alert.vehicle
                    updatedVehicle.status = .maintenance
                    try? await VehicleService.updateVehicle(updatedVehicle)
                    
                    // Reload data to reflect assignment instantly
                    Task {
                        await viewModel.loadData()
                    }
                }
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
                        maintenanceStaff: viewModel.profiles.filter { $0.role == "maintenance" },
                        onAssignSuccess: {
                            Task {
                                await viewModel.loadData()
                            }
                        }
                    )
                case .fuelAnalytics:
                    FleetFuelAnalyticsView(adminId: viewModel.adminId)
                case .esgCompliance:
                    ESGComplianceDashboardView(
                        trips: viewModel.trips,
                        vehicles: viewModel.vehicles,
                        fuelLogs: []
                    )
                }
            }
        }
        .task { }
        .onChange(of: authViewModel.currentUser?.id, initial: true) { _, _ in
            guard let adminId = authViewModel.currentUserId else { return }
            viewModel.adminId = adminId
            Task {
                await viewModel.loadData()
                viewModel.setupRealtime()
            }
        }
    }

    // MARK: - Fleet Overview Card

    private var fleetOverviewCard: some View {
        ZStack {
            NavigationLink(value: DashboardDestination.vehiclesRoot) {
                EmptyView()
            }
            .opacity(0)

            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.teal.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: "truck.box")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.teal)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Fleet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(viewModel.totalVehicles) vehicles")
                            .font(.headline)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(.tertiaryLabel))
                }

                Divider()
                    .padding(.vertical, 14)

                HStack(spacing: 0) {
                    kpiCell(
                        value: "\(viewModel.driversOnTrip)",
                        label: "Active",
                        color: .green
                    )
                    Divider().frame(height: 36)
                    kpiCell(
                        value: "\(max(0, viewModel.totalVehicles - viewModel.driversOnTrip - viewModel.inServiceVehicles))",
                        label: "Idle",
                        color: .orange
                    )
                    Divider().frame(height: 36)
                    kpiCell(
                        value: "\(viewModel.inServiceVehicles)",
                        label: "Service",
                        color: .red
                    )
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func kpiCell(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Live Fleet Map

    private var liveFleetSection: some View {
        let activeTrips = viewModel.trips.filter { $0.status == .active }
        return Section {
            DashboardMapView(
                activeTrips: activeTrips,
                routes: viewModel.routes,
                profiles: viewModel.profiles,
                vehicleLocations: viewModel.vehicleLocations
            )
            .frame(height: 240)
            .listRowInsets(EdgeInsets())

            if !activeTrips.isEmpty {
                ForEach(activeTrips) { trip in
                    let route = viewModel.routes.first { $0.id == trip.routeId }
                    let driverName = viewModel.driverName(for: trip.driverId)

                    NavigationLink(value: DashboardDestination.orderDetail(trip)) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "person.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.green)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(driverName)
                                    .font(.subheadline.weight(.medium))
                                if let start = route?.startLocation, let end = route?.endLocation {
                                    Text("\(start) → \(end)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }

                            Spacer()
                            StatusBadge(text: "Active", color: .green)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        } header: {
            HStack {
                Text("Live Fleet")
                Spacer()
                if !activeTrips.isEmpty {
                    HStack(spacing: 4) {
                        Circle().fill(.green).frame(width: 6, height: 6)
                        Text("\(activeTrips.count) on route")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .textCase(.none)
                    }
                }
            }
        }
    }

    // MARK: - Driver Alerts

    private var liveDriverAlertsSection: some View {
        let incidents = viewModel.recentVoiceIncidents.filter { incident in
            let trip = viewModel.trips.first(where: { $0.id == incident.tripId })
            return trip?.status != .completed
        }
        return Section {
            if incidents.isEmpty {
                Label("No driver alerts", systemImage: "checkmark.shield")
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
                Text("Driver Alerts")
                if !incidents.isEmpty {
                    Text("\(incidents.count)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.orange)
                        .clipShape(Capsule())
                }
            }
        }
    }


    // MARK: - Resolved Maintenance Cost Section

    private var resolvedMaintenanceCostSection: some View {
        // Show resolved records with a recorded cost, most recent first, last 30 days
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let resolved = viewModel.maintenanceHistory
            .filter { ($0.cost ?? 0) > 0 && ($0.completedAt ?? .distantPast) >= cutoff }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }

        return Section {
            if resolved.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.teal)
                    Text("No resolved work orders with costs in the last 30 days")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } else {
                ForEach(resolved) { history in
                    ResolvedMaintenanceCostCard(
                        history: history,
                        vehicle: viewModel.vehicles.first { $0.id == history.vehicleId }
                    )
                }
            }
        } header: {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.teal)
                Text("Resolved Work Orders – Cost")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
                if !resolved.isEmpty {
                    let total = resolved.compactMap { $0.cost }.reduce(0, +)
                    Text(String(format: "₹ %.0f total", total))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.teal)
                        .textCase(.none)
                }
            }
        }
    }

    private var predictiveMaintenanceSection: some View {
        let alerts = viewModel.predictiveAlerts
        
        return Section {
            if alerts.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.purple)
                    Text("All vehicles performing optimally")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            } else {
                ForEach(alerts.prefix(3)) { alert in
                    PredictiveAlertCardView(alert: alert) {
                        selectedAlertForAssignment = alert
                    }
                }
                if alerts.count > 3 {
                    NavigationLink(value: DashboardDestination.allMaintenanceAlerts) {
                        Text("See All AI Recommendations (\(alerts.count))")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.purple)
                    }
                }
            }
        } header: {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.purple)
                Text("AI Predictive Maintenance")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func incidentRow(_ incident: TripIncident) -> some View {
        let trip = viewModel.trips.first(where: { $0.id == incident.tripId })
        let driverName = viewModel.driverName(for: incident.driverId ?? trip?.driverId)

        return HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(incidentColor(incident.incidentType).opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: incidentIcon(incident.incidentType))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(incidentColor(incident.incidentType))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(incident.incidentType)
                        .font(.subheadline.weight(.medium))
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
                Label(driverName, systemImage: "person.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 1)
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
    }
}

// MARK: - Predictive Alert Card

struct PredictiveAlertCardView: View {
    let alert: PredictiveMaintenanceAlert
    let onSelect: () -> Void

    private var accentColor: Color {
        alert.severity == .critical ? .red : .orange
    }

    private var severityLabel: String {
        alert.severity == .critical ? "Critical" : "Warning"
    }

    private var severityIcon: String {
        alert.severity == .critical ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill"
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(alert.vehicle.make ?? "") \(alert.vehicle.model ?? "")")
                                .font(.subheadline.weight(.medium))
                            Text(alert.vehicle.licensePlate ?? "")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        StatusBadge(text: severityLabel, color: accentColor)
                    }

                    Text(alert.reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - All Maintenance Alerts

struct AllMaintenanceAlertsView: View {
    let alerts: [PredictiveMaintenanceAlert]
    let maintenanceStaff: [Profile]
    let onAssignSuccess: () -> Void
    @State private var selectedAlert: PredictiveMaintenanceAlert?

    var body: some View {
        List {
            ForEach(alerts) { alert in
                PredictiveAlertCardView(alert: alert) {
                    selectedAlert = alert
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("All Alerts")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedAlert) { alert in
            MaintenanceAssignmentSheet(
                vehicleName: "\(alert.vehicle.make ?? "") \(alert.vehicle.model ?? "")",
                licensePlate: alert.vehicle.licensePlate ?? "No Plate",
                severityLabel: alert.severity == .critical ? "Critical" : "Warning",
                severityColor: alert.severity == .critical ? .red : .orange,
                severityIcon: alert.severity == .critical ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill",
                issueTitle: "Predicted Issue",
                issueDescription: alert.reason,
                recommendationTitle: "Recommended Action",
                recommendationDescription: alert.recommendation,
                maintenanceStaff: maintenanceStaff
            ) { staffId, notes in
                let workOrderId = try await WorkOrderService.createWorkOrder(
                    vehicleId: alert.vehicle.id,
                    createdBy: nil,
                    assignedTo: staffId,
                    priority: alert.severity == .critical ? .high : .medium,
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
                var updatedVehicle = alert.vehicle
                updatedVehicle.status = .maintenance
                try? await VehicleService.updateVehicle(updatedVehicle)
                
                onAssignSuccess()
            }
        }
    }
}

// MARK: - Resolved Maintenance Cost Card

struct ResolvedMaintenanceCostCard: View {
    let history: MaintenanceHistory
    let vehicle: Vehicle?

    private var vehicleName: String {
        guard let v = vehicle else { return "Unknown Vehicle" }
        return "\(v.make ?? "") \(v.model ?? "")"
    }

    private var vehiclePlate: String {
        vehicle?.licensePlate ?? ""
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.teal.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.teal)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(vehicleName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        if !vehiclePlate.isEmpty {
                            Text(vehiclePlate)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    // Cost badge
                    if let cost = history.cost {
                        Text(String(format: "₹ %.0f", cost))
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.teal)
                            .clipShape(Capsule())
                    }
                }

                if let details = history.serviceDetails, !details.isEmpty {
                    Text(details.components(separatedBy: "\n").first ?? details)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if let date = history.completedAt {
                    Label(date.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                        .font(.caption2)
                        .foregroundStyle(Color(.tertiaryLabel))
                }
            }
        }
        .padding(.vertical, 4)
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
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.orange.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: "drop.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.orange)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Fuel Analytics")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(viewModel.totalTrips) Trips Completed")
                            .font(.headline)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(.tertiaryLabel))
                }

                Divider()
                    .padding(.vertical, 14)

                // Stats breakdown row
                HStack(spacing: 0) {
                    fuelKpiCell(
                        value: String(format: "%.0f km", viewModel.totalDistance),
                        label: "Total Distance",
                        color: .blue
                    )
                    Divider().frame(height: 36)
                    fuelKpiCell(
                        value: String(format: "%.1f L", viewModel.totalLiters),
                        label: "Fuel Used",
                        color: .orange
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

    private func fuelKpiCell(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    DashboardView()
        .environment(AuthViewModel())
}
