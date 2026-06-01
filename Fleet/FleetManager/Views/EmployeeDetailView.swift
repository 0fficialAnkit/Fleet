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

    @State private var trips:    [Trip] = []
    @State private var tasks:    [MaintenanceTask] = []
    @State private var routes:   [Route] = []
    @State private var vehicles: [Vehicle] = []
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
                            .frame(width: 110, height: 110)
                        Image(systemName: viewModel.getIcon(for: currentRoleName))
                            .font(.system(size: 44))
                            .foregroundColor(viewModel.getColor(for: currentRoleName))
                    }
                    .padding(.bottom, 8)

                    Text(currentProfile.fullName)
                        .font(.title.bold())
                        .foregroundColor(Color.primary)

                    Text(currentRoleName)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(viewModel.getColor(for: currentRoleName))
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
                        HStack {
                            Spacer()
                            VStack(spacing: 10) {
                                Image(systemName: "road.lanes")
                                    .font(.system(size: 32))
                                    .foregroundStyle(Color(.quaternaryLabel))
                                Text("No trips yet")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondary)
                            }
                            Spacer()
                        }
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

            // MARK: Work History — same pattern for maintenance staff
            if currentProfile.role == "maintenance" {
                if isLoadingHistory {
                    Section(header: Text("Work History")) {
                        HStack { Spacer(); ProgressView(); Spacer() }
                    }
                } else if tasks.isEmpty {
                    Section(header: Text("Work History")) {
                        HStack {
                            Spacer()
                            VStack(spacing: 10) {
                                Image(systemName: "wrench.and.screwdriver")
                                    .font(.system(size: 32))
                                    .foregroundStyle(Color(.quaternaryLabel))
                                Text("No tasks yet")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondary)
                            }
                            Spacer()
                        }
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
        .navigationBarTitleDisplayMode(.inline)
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
                            .foregroundColor(.white)
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

    // MARK: - Data Loading

    private func loadHistory() async {
        isLoadingHistory = true
        do {
            if currentProfile.role == "driver" {
                async let t = TripService.fetchTripsForDriver(driverId: currentProfile.id)
                async let r = RouteService.fetchAllRoutes()
                async let v = VehicleService.fetchAllVehicles()
                trips    = try await t
                routes   = try await r
                vehicles = try await v
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
                .foregroundColor(Color(.tertiaryLabel))
                .frame(width: 24)

            Text(title)
                .font(.body.weight(.medium))
                .foregroundColor(Color.secondary)

            Spacer()

            Text(value)
                .font(.body)
                .foregroundColor(valueColor)
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
