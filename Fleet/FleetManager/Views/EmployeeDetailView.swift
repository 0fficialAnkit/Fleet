import SwiftUI
import Supabase

struct EmployeeDetailView: View {
    let profile: Profile
    let viewModel: EmployeesViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var isShowingEditSheet = false
    @State private var deleteError: String?
    @State private var isSharingCredentials = false
    @State private var shareCredentialsAlertMessage: String?

    @State private var trips:         [Trip]         = []
    @State private var tasks:         [MaintenanceTask] = []
    @State private var routes:        [Route]        = []
    @State private var vehicles:      [Vehicle]      = []
    @State private var routeBreaches: [RouteBreach]  = []   // geofence breach history
    @State private var isLoadingHistory = false

    var currentProfile: Profile {
        viewModel.profiles.first { $0.id == profile.id } ?? profile
    }

    var currentRoleName: String {
        viewModel.getRole(for: currentProfile)
    }

    // Pre-sorted so we can use .first / .dropFirst safely
    private var tripsSorted: [Trip] {
        trips.sorted { ($0.startTime ?? .distantPast) > ($1.startTime ?? .distantPast) }
    }

    private var tasksSorted: [MaintenanceTask] {
        tasks.sorted { ($0.scheduledDate ?? .distantPast) > ($1.scheduledDate ?? .distantPast) }
    }

    // Removed credentialsShareText as we now send email via backend

    var body: some View {
        List {

            // MARK: Header
            Section {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(viewModel.getColor(for: currentRoleName).opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: viewModel.getIcon(for: currentRoleName))
                            .font(.system(size: 44))
                            .foregroundStyle(viewModel.getColor(for: currentRoleName))
                    }
                    .padding(.bottom, 8)

                    Text(currentProfile.fullName)
                        .font(.title.bold())
                        .foregroundStyle(Color.primary)

                    Text(currentRoleName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(viewModel.getColor(for: currentRoleName))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(viewModel.getColor(for: currentRoleName).opacity(0.15))
                        .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            // MARK: Info
            Section {
                InfoRowView(icon: "person.fill",  title: "Full Name", value: currentProfile.fullName)
                InfoRowView(icon: "envelope.fill", title: "Email",     value: currentProfile.email)
                InfoRowView(icon: "phone.fill",    title: "Phone",     value: currentProfile.phone ?? "Not Provided")

                if currentProfile.role == "driver" {
                    InfoRowView(icon: "lanyardcard.fill", title: "Driver License",
                                value: currentProfile.licenseNumber ?? "Not Provided")
                }

                let status = currentProfile.userStatus ?? .active
                InfoRowView(
                    icon: status == .active ? "checkmark.circle.fill" : "xmark.circle.fill",
                    title: "Status / State",
                    value: status.rawValue.capitalized,
                    valueColor: status == .active ? .green : .secondary
                )

                if let date = currentProfile.createdAt {
                    InfoRowView(icon: "calendar", title: "Joined",
                                value: date.formatted(date: .abbreviated, time: .omitted))
                }
            }

            // MARK: Trip History — each trip is its own top-level Section = separate card
            if currentProfile.role == "driver" {
                if isLoadingHistory {
                    Section(header: Text("Trip History")) {
                        HStack { Spacer(); ProgressView(); Spacer() }
                    }
                } else if trips.isEmpty {
                    Section(header: Text("Trip History")) {
                        ContentUnavailableView(
                            "No Trips",
                            systemImage: "road.lanes",
                            description: Text("This driver hasn't completed any trips yet.")
                        )
                        .padding(.vertical, 20)
                        .listRowBackground(Color.clear)
                    }
                } else {
                    Section(header: Text("Trip History")) {
                        ForEach(tripsSorted) { trip in
                            tripCard(trip)
                        }
                    }
                }
            }

            // MARK: Safety & Compliance — only for drivers
            if currentProfile.role == "driver" {
                let totalTrips    = trips.count
                let breachedTrips = Set(routeBreaches.map { $0.tripId }).count
                let cleanTrips    = max(0, totalTrips - breachedTrips)
                let compliance    = totalTrips > 0
                    ? Int(Double(cleanTrips) / Double(totalTrips) * 100) : 100
                let worst         = routeBreaches.map { $0.distanceFromCenter }.max() ?? 0

                // Matches the existing InfoRowView card style used everywhere in this view
                Section(header: Text("Safety & Compliance")) {
                    InfoRowView(
                        icon:       "shield.checkered",
                        title:      "Route Compliance",
                        value:      "\(compliance)%",
                        valueColor: complianceColor(compliance)
                    )
                    InfoRowView(
                        icon:       compliance >= 90 ? "checkmark.circle.fill" : "exclamationmark.circle.fill",
                        title:      "Rating",
                        value:      complianceLabel(compliance),
                        valueColor: complianceColor(compliance)
                    )
                    InfoRowView(
                        icon:  "road.lanes",
                        title: "Compliant Trips",
                        value: "\(cleanTrips) of \(totalTrips)"
                    )
                    if !routeBreaches.isEmpty {
                        InfoRowView(
                            icon:       "exclamationmark.triangle.fill",
                            title:      "Route Violations",
                            value:      "\(routeBreaches.count)",
                            valueColor: .red
                        )
                        InfoRowView(
                            icon:       "arrow.up.right",
                            title:      "Worst Deviation",
                            value:      String(format: "%.1f km", worst / 1000),
                            valueColor: severityColorEmployee(worst)
                        )
                    }
                }

                // Violation history — grouped by trip, collapsible
                // Violation history — flat list of cards
                if !routeBreaches.isEmpty {
                    Section {
                        ForEach(Array(routeBreaches.enumerated()), id: \.element.id) { idx, v in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(.red)
                                        .frame(width: 8, height: 8)
                                    Text("Violation #\(idx + 1)")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("Trip #\(v.tripId.uuidString.prefix(8).uppercased())")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(Color(.tertiaryLabel))
                                }
                                
                                VStack(spacing: 0) {
                                    LabeledContent("Time") {
                                        Text(v.occurredAt?.formatted(date: .abbreviated, time: .shortened) ?? "—")
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 10)
                                    
                                    Divider()
                                    
                                    LabeledContent("Distance Off-Route") {
                                        Text(String(format: "%.1f km", v.distanceFromCenter / 1000))
                                            .foregroundStyle(severityColorEmployee(v.distanceFromCenter))
                                            .fontWeight(.semibold)
                                    }
                                    .padding(.vertical, 10)
                                    
                                    Divider()
                                    
                                    LabeledContent("Route Boundary Radius") {
                                        Text(String(format: "%.1f km", v.fenceRadius / 1000))
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 10)
                                    
                                    Divider()
                                    
                                    LabeledContent("Severity") {
                                        Text(severityLabelEmployee(v.distanceFromCenter))
                                            .foregroundStyle(severityColorEmployee(v.distanceFromCenter))
                                            .fontWeight(.semibold)
                                    }
                                    .padding(.vertical, 10)
                                }
                                .padding(.horizontal, 16)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.vertical, 6)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    } header: {
                        HStack {
                            Text("Route Deviation Alert")
                                .foregroundStyle(.red)
                            Spacer()
                            Text("\(routeBreaches.count)")
                                .font(.caption.weight(.bold)).foregroundStyle(.white)
                                .padding(.horizontal, 7).padding(.vertical, 2)
                                .background(.red, in: Capsule())
                                .textCase(nil)
                        }
                    }
                }
            }

            // MARK: Work History — same pattern for maintenance staff
            if currentProfile.role == "maintenance" {
                if isLoadingHistory {
                    Section(header: Text("Work History")) {
                        HStack { Spacer(); ProgressView(); Spacer() }
                    }
                } else if tasks.isEmpty {
                    Section(header: Text("Work History")) {
                        ContentUnavailableView(
                            "No Tasks",
                            systemImage: "wrench.and.screwdriver",
                            description: Text("No maintenance tasks assigned yet.")
                        )
                        .padding(.vertical, 20)
                        .listRowBackground(Color.clear)
                    }
                } else {
                    Section(header: Text("Work History")) {
                        ForEach(tasksSorted) { task in
                            maintenanceCard(task)
                        }
                    }
                }
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        Task {
                            isSharingCredentials = true
                            do {
                                try await ProfileService.invokeShareCredentials(for: currentProfile)
                                shareCredentialsAlertMessage = "Credentials successfully sent to \(currentProfile.email)."
                            } catch let error as FunctionsError {
                                switch error {
                                case .httpError(let code, let data):
                                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                                       let serverError = json["error"] as? String {
                                        shareCredentialsAlertMessage = "Error: \(serverError)"
                                    } else {
                                        shareCredentialsAlertMessage = "HTTP Error \(code)"
                                    }
                                case .relayError:
                                    shareCredentialsAlertMessage = "Network relay error"
                                }
                            } catch {
                                shareCredentialsAlertMessage = "Failed to send credentials: \(error.localizedDescription)"
                            }
                            isSharingCredentials = false
                        }
                    } label: {
                        Label("Share Credentials", systemImage: "envelope")
                    }
                    Button { isShowingEditSheet = true } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        Task {
                            do {
                                try await viewModel.deleteEmployee(currentProfile)
                                dismiss()
                            } catch {
                                deleteError = error.localizedDescription
                            }
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Color.primary)
                }
            }
        }
        .sheet(isPresented: $isShowingEditSheet) {
            EditEmployeeView(profile: currentProfile, viewModel: viewModel)
        }
        .alert("Unable to Delete Driver/Employee", isPresented: Binding(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let msg = deleteError {
                Text(msg)
            }
        }
        .alert("Share Credentials", isPresented: Binding(
            get: { shareCredentialsAlertMessage != nil },
            set: { if !$0 { shareCredentialsAlertMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let msg = shareCredentialsAlertMessage {
                Text(msg)
            }
        }
        .overlay {
            if isSharingCredentials {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.2)
                        Text("Sending credentials...")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.white)
                    }
                    .padding(32)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
            }
        }
        .task { await loadHistory() }
    }

    // MARK: - Trip Card

    private func tripCard(_ trip: Trip) -> some View {
        let route = routes.first { $0.id == trip.routeId }
        let start = route?.startLocation ?? "—"
        let end   = route?.endLocation   ?? "—"
        let ordersVM = OrdersViewModel(
            trips:    trips,
            routes:   routes,
            profiles: viewModel.profiles,
            vehicles: vehicles
        )

        return NavigationLink {
            OrderDetailView(trip: trip, viewModel: ordersVM)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(start) → \(end)")
                            .font(.body.bold())
                            .foregroundStyle(Color.primary)
                            .lineLimit(1)
                        if let type = trip.orderType {
                            Text(type.displayName)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.secondary)
                        }
                    }
                    Spacer()
                    StatusBadge(
                        text: trip.status?.rawValue.capitalized ?? "Unknown",
                        color: tripStatusColor(trip.status)
                    )
                }

                HStack(spacing: 16) {
                    if let date = trip.startTime {
                        Label(date.formatted(date: .abbreviated, time: .shortened),
                              systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                    if let dist = trip.distance {
                        Label(String(format: "%.1f km", dist), systemImage: "ruler")
                            .font(.caption)
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }

    // MARK: - Maintenance Card

    private func maintenanceCard(_ task: MaintenanceTask) -> some View {
        let vehicle     = vehicles.first { $0.id == task.vehicleId }
        let vehicleName = [vehicle?.make, vehicle?.model].compactMap { $0 }.joined(separator: " ")

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(task.taskType?.rawValue
                            .replacingOccurrences(of: "_", with: " ")
                            .capitalized ?? "Maintenance Task")
                        .font(.body.bold())
                        .foregroundStyle(Color.primary)
                    if let desc = task.description {
                        Text(desc)
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
                StatusBadge(
                    text: taskStatusLabel(task.status),
                    color: taskStatusColor(task.status)
                )
            }

            HStack(spacing: 16) {
                if !vehicleName.isEmpty {
                    Label(vehicleName, systemImage: "truck.box.fill")
                        .font(.caption)
                        .foregroundStyle(Color(.tertiaryLabel))
                }
                if let date = task.scheduledDate {
                    Label(date.formatted(date: .abbreviated, time: .omitted),
                          systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(Color(.tertiaryLabel))
                }
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Safety helpers

    private func complianceColor(_ pct: Int) -> Color {
        if pct >= 90 { return .green }
        if pct >= 70 { return .orange }
        return .red
    }

    private func complianceLabel(_ pct: Int) -> String {
        if pct == 100 { return "Perfect compliance" }
        if pct >= 90  { return "Good — minor violations" }
        if pct >= 70  { return "Fair — review needed" }
        return "Poor — training required"
    }

    private func severityColorEmployee(_ dist: Double) -> Color {
        let km = dist / 1000
        if km < 1 { return .yellow }
        if km < 3 { return .orange }
        return .red
    }

    private func severityLabelEmployee(_ dist: Double) -> String {
        let km = dist / 1000
        if km < 1 { return "Minor" }
        if km < 3 { return "Moderate" }
        return "Critical"
    }

    private func statPill(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.subheadline.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(2)
    }

    // MARK: - Data Loading

    private func loadHistory() async {
        isLoadingHistory = true
        do {
            if currentProfile.role == "driver" {
                async let t  = TripService.fetchTripsForDriver(driverId: currentProfile.id)
                async let r  = RouteService.fetchAllRoutes()
                async let v  = VehicleService.fetchAllVehicles()
                async let br = RouteBreachService.fetchBreaches(forDriver: currentProfile.id)
                trips         = try await t
                routes        = try await r
                vehicles      = try await v
                routeBreaches = (try? await br) ?? []
            } else if currentProfile.role == "maintenance" {
                async let ta = MaintenanceTaskService.fetchTasksForUser(assignedTo: currentProfile.id)
                async let v  = VehicleService.fetchAllVehicles()
                tasks    = try await ta
                vehicles = try await v
            }
        } catch {
            print("[EmployeeDetailView] loadHistory error: \(error)")
        }
        isLoadingHistory = false
    }

    // MARK: - Helpers

    private func tripStatusColor(_ status: TripStatus?) -> Color {
        switch status {
        case .scheduled: return .blue
        case .active:    return .green
        case .completed: return .green
        case .cancelled: return .red
        case .none:      return .secondary
        }
    }

    private func taskStatusLabel(_ status: MaintenanceTaskStatus?) -> String {
        switch status {
        case .pending:    return "Pending"
        case .inProgress: return "In Progress"
        case .completed:  return "Completed"
        case .cancelled:  return "Cancelled"
        case .none:       return "Unknown"
        }
    }

    private func taskStatusColor(_ status: MaintenanceTaskStatus?) -> Color {
        switch status {
        case .pending:    return .blue
        case .inProgress: return .orange
        case .completed:  return .green
        case .cancelled:  return .red
        case .none:       return .secondary
        }
    }
}

// MARK: - Info Row

struct InfoRowView: View {
    let icon: String
    let title: String
    let value: String
    var valueColor: Color = Color.primary

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color(.tertiaryLabel))
                .frame(width: 24)

            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(Color.secondary)

            Spacer()

            Text(value)
                .font(.body)
                .foregroundStyle(valueColor)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        EmployeeDetailView(
            profile: Profile(id: UUID(), fullName: "Ravi Kumar", email: "ravi@fleet.in", role: "driver"),
            viewModel: EmployeesViewModel()
        )
        .preferredColorScheme(.dark)
    }
}
