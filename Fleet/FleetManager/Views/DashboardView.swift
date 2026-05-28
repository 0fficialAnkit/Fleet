import SwiftUI

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
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    List {
                        Section {
                            fleetOverviewCard
                        }

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
            MaintenanceAssignmentSheet(alert: alert, maintenanceStaff: maintenanceStaff)
        }
    }
}

// MARK: - Maintenance Assignment Sheet

struct MaintenanceAssignmentSheet: View {
    let alert: PredictiveMaintenanceAlert
    let maintenanceStaff: [Profile]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedStaffId: UUID?
    @State private var notes: String = ""
    @State private var isAssigning = false
    @State private var assignSuccess = false
    @State private var errorMessage: String?

    private var accentColor: Color {
        alert.severity == .critical ? Color.red : Color.orange
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Vehicle summary card
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(accentColor.opacity(0.12))
                                .frame(width: 56, height: 56)
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .font(.system(size: 26, weight: .medium))
                                .foregroundStyle(accentColor)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(alert.vehicle.make ?? "") \(alert.vehicle.model ?? "")")
                                .font(.title3.bold())
                            Text(alert.vehicle.licensePlate ?? "No Plate")
                                .font(.subheadline)
                                .foregroundStyle(Color.secondary)
                            HStack(spacing: 4) {
                                Image(systemName: alert.severity == .critical ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                                    .font(.system(size: 11))
                                Text(alert.severity == .critical ? "Critical" : "Warning")
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(accentColor)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    // Alert details
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Predicted Issue", systemImage: "magnifyingglass")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                        Text(alert.reason)
                            .font(.body)
                            .foregroundStyle(Color.primary)

                        Divider()

                        Label("Recommended Action", systemImage: "lightbulb.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                        Text(alert.recommendation)
                            .font(.body)
                            .foregroundStyle(Color.primary)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    // Staff picker
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Assign to Maintenance Staff", systemImage: "person.2.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                            .padding(.horizontal)

                        if maintenanceStaff.isEmpty {
                            HStack {
                                Image(systemName: "person.fill.xmark")
                                    .foregroundStyle(Color.secondary)
                                Text("No maintenance staff available")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondary)
                            }
                            .padding()
                        } else {
                            ForEach(maintenanceStaff, id: \.id) { person in
                                Button(action: { selectedStaffId = person.id }) {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.teal.opacity(0.15))
                                                .frame(width: 40, height: 40)
                                            Text(String(person.fullName.prefix(1)).uppercased())
                                                .font(.system(size: 17, weight: .semibold))
                                                .foregroundStyle(Color.teal)
                                        }
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(person.fullName)
                                                .font(.body.weight(.medium))
                                                .foregroundStyle(Color.primary)
                                            if let phone = person.phone {
                                                Text(phone)
                                                    .font(.caption)
                                                    .foregroundStyle(Color.secondary)
                                            }
                                        }
                                        Spacer()
                                        if selectedStaffId == person.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(Color.teal)
                                                .font(.system(size: 20))
                                        } else {
                                            Circle()
                                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1.5)
                                                .frame(width: 22, height: 22)
                                        }
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal)
                                    .background(
                                        selectedStaffId == person.id
                                            ? Color.teal.opacity(0.06)
                                            : Color(UIColor.secondarySystemGroupedBackground)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(selectedStaffId == person.id ? Color.teal.opacity(0.4) : Color.clear, lineWidth: 1)
                                    )
                                    .padding(.horizontal)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Notes (optional)", systemImage: "note.text")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal)

                    if let err = errorMessage {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(Color.red)
                            .padding(.horizontal)
                    }

                    // Assign button
                    Button(action: assignTask) {
                        HStack {
                            if isAssigning {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 4)
                            } else if assignSuccess {
                                Image(systemName: "checkmark")
                                    .font(.body.bold())
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.body.bold())
                            }
                            Text(assignSuccess ? "Assigned!" : "Assign Task")
                                .font(.body.bold())
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            selectedStaffId != nil && !assignSuccess
                                ? Color.teal
                                : Color(UIColor.systemFill)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .padding(.horizontal)
                    }
                    .disabled(selectedStaffId == nil || isAssigning || assignSuccess)
                }
                .padding(.vertical)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Assign Maintenance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func assignTask() {
        guard let staffId = selectedStaffId else { return }
        isAssigning = true
        errorMessage = nil
        Task {
            do {
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
                await MainActor.run {
                    isAssigning = false
                    assignSuccess = true
                }
                try? await Task.sleep(for: .seconds(1.2))
                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run {
                    isAssigning = false
                    errorMessage = "Failed to assign: \(error.localizedDescription)"
                }
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

