import SwiftUI

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @State private var isShowingProfile = false
    @State private var showingNotifications = false
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var navigationPath = NavigationPath()
    @State private var complianceStore = ComplianceSettingsStore.shared

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if viewModel.isLoading && viewModel.vehicles.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    List {
                        Section {
                            fleetOverviewCard
                        }

                        complianceExpiryAlertsSection

                        liveFleetSection

                        recentOrdersSection

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
                        Image(systemName: "bell")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color.primary)
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
                    VehiclesRootView(path: $navigationPath)
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
                        value: max(0, viewModel.totalVehicles - viewModel.driversOnTrip - viewModel.predictiveAlerts.count),
                        label: "Idle",
                        color: Color.orange
                    )
                    FleetStatPill(
                        value: viewModel.predictiveAlerts.count,
                        label: "Service",
                        color: Color.red
                    )
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Recent Orders

    private var recentOrdersSection: some View {
        Section(header: HStack {
            Text("Recent Orders")
            Spacer()
            Button("See All") {
                // Action
            }
            .font(.footnote)
            .textCase(.none)
        }) {
            if viewModel.recentOrders.isEmpty {
                Text("No orders yet.")
                    .font(.body)
                    .foregroundStyle(Color.secondary)
            } else {
                ForEach(viewModel.recentOrders) { trip in
                    NavigationLink(value: DashboardDestination.orderDetail(trip)) {
                        TripCardView(trip: trip, viewModel: viewModel)
                    }
                }
            }
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

    // MARK: - Automatic Expiry Alerts

    private var expiringVehicles: [(vehicle: Vehicle, type: String, status: ComplianceStatus, daysLeft: Int)] {
        var alerts: [(vehicle: Vehicle, type: String, status: ComplianceStatus, daysLeft: Int)] = []
        for vehicle in viewModel.vehicles {
            let key = vehicle.licensePlate ?? vehicle.id.uuidString
            let settings = complianceStore.settings(for: key)

            if let date = settings.insuranceExpiry {
                let days = complianceStore.daysUntilExpiry(for: date) ?? 0
                if days <= 30 {
                    let status = complianceStore.insuranceStatus(for: key)
                    alerts.append((vehicle, "Insurance Expiry", status, days))
                }
            }

            if let date = settings.serviceExpiry {
                let days = complianceStore.daysUntilExpiry(for: date) ?? 0
                if days <= 30 {
                    let status = complianceStore.serviceStatus(for: key)
                    alerts.append((vehicle, "Service Due", status, days))
                }
            }
        }
        return alerts.sorted(by: { $0.daysLeft < $1.daysLeft })
    }

    private var complianceExpiryAlertsSection: some View {
        let alerts = expiringVehicles
        return Group {
            if !alerts.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Compliance Alerts", action: "Manage") {
                        navigationPath.append(DashboardDestination.vehiclesRoot)
                    }
                    .padding(.horizontal, 16)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<alerts.count, id: \.self) { idx in
                                let alert = alerts[idx]
                                let isExpired = alert.daysLeft < 0
                                NavigationLink(value: DashboardDestination.vehiclesRoot) {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(alert.status.color.opacity(0.15))
                                                .frame(width: 40, height: 40)
                                            Image(systemName: alert.status.icon)
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundStyle(alert.status.color)
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(alert.vehicle.make ?? "") \(alert.vehicle.model ?? "")")
                                                .font(.subheadline.bold())
                                                .foregroundStyle(Color.primary)

                                            Text("\(alert.type): \(isExpired ? "Expired" : "Expires in \(alert.daysLeft) day\(alert.daysLeft == 1 ? "" : "s")")")
                                                .font(.caption)
                                                .foregroundStyle(alert.status.color)
                                        }

                                        Spacer()

                                        Text(alert.vehicle.licensePlate ?? "No Plate")
                                            .font(.system(size: 10, weight: .bold))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color(.tertiarySystemGroupedBackground))
                                            .clipShape(Capsule())
                                    }
                                    .padding(14)
                                    .frame(width: 280)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(alert.status.color.opacity(0.25), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
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
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.primary)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(color.opacity(0.25), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                let task = MaintenanceTask(
                    id: UUID(),
                    workOrderId: nil,
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

#Preview {
    DashboardView()
        .environment(AuthViewModel())
}
