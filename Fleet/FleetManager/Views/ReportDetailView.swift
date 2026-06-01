import SwiftUI

struct ReportDetailView: View {

    let report: IssueReport
    @State var viewModel: ReportsViewModel
    @State private var selectedStaffId: UUID?
    @State private var showingAssignment = false
    @Environment(\.dismiss) private var dismiss

    init(report: IssueReport, viewModel: ReportsViewModel) {
        self.report = report
        self.viewModel = viewModel
        _selectedStaffId = State(initialValue: report.assignedTo)
    }

    // MARK: - Lookups

    var vehicle: Vehicle?       { viewModel.vehicle(for: report.vehicleId) }
    var driverProfile: Profile? { viewModel.profile(for: report.reportedBy) }
    var lastTrip: Trip?         { viewModel.lastTrip(for: report.vehicleId) }
    var lastDriver: Profile? {
        guard let trip = lastTrip, let id = trip.driverId else { return nil }
        let p = viewModel.profile(for: id)
        return p?.id == report.reportedBy ? nil : p   // only show if different from reporter
    }

    @State private var lastTripRoute: Route? = nil

    // MARK: - Description parsing

    var cleanDescription: String {
        report.description
            .components(separatedBy: "\n\nLocation:").first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? report.description
    }

    var meta: [String: String] {
        var dict: [String: String] = [:]
        for line in report.description.components(separatedBy: "\n") {
            if let range = line.range(of: ": ") {
                let key = String(line[..<range.lowerBound])
                let val = String(line[range.upperBound...])
                dict[key] = val
            }
        }
        return dict
    }

    var photoURLs: [URL] {
        report.description
            .components(separatedBy: "\n")
            .filter { $0.hasPrefix("- http") }
            .compactMap { URL(string: String($0.dropFirst(2))) }
    }

    var isNotDriveable: Bool {
        meta["Driveable"]?.contains("No") == true
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {

                // ── Identity ──────────────────────────────────────
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(viewModel.severityColor(report.severity).opacity(0.12))
                                .frame(width: 52, height: 52)
                            Image(systemName: "truck.box.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(viewModel.severityColor(report.severity))
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(report.vehicleName)
                                .font(.headline)
                            Text(report.licensePlate)
                                .font(.subheadline)
                                .foregroundStyle(Color.teal)
                                .fontDesign(.monospaced)
                        }

                        Spacer()

                        StatusBadge(
                            text: report.status.rawValue,
                            color: report.status.color,
                            icon: report.status.icon
                        )
                    }
                    .padding(.vertical, 4)
                }

                // ── Issue Overview ────────────────────────────────
                Section("Issue Overview") {
                    LabeledContent("Category", value: report.issueCategory)

                    HStack {
                        Text("Severity")
                        Spacer()
                        StatusBadge(
                            text: report.severity.rawValue.capitalized,
                            color: viewModel.severityColor(report.severity)
                        )
                    }

                    LabeledContent("Reported") {
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(report.submittedAt.formatted(date: .abbreviated, time: .omitted))
                            Text(report.submittedAt.formatted(date: .omitted, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // ── Incident Details ──────────────────────────────
                Section("Incident Details") {
                    if let loc = meta["Location"] {
                        LabeledContent("Where Noticed", value: loc)
                    }
                    if let rat = meta["Reported at"] {
                        LabeledContent("Time of Incident", value: rat)
                    }
                    if let drv = meta["Driveable"] {
                        HStack {
                            Text("Vehicle Driveable")
                            Spacer()
                            Text(drv)
                                .fontWeight(.medium)
                                .foregroundStyle(isNotDriveable ? Color.red : Color.green)
                        }
                    }
                    if !cleanDescription.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Description")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            Text(cleanDescription)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 4)
                    }
                }

                // ── Damage Photos ─────────────────────────────────
                if !photoURLs.isEmpty {
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(photoURLs, id: \.absoluteString) { url in
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let img):
                                            img.resizable()
                                                .scaledToFill()
                                                .frame(width: 110, height: 110)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                        case .failure:
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color(.tertiarySystemFill))
                                                .frame(width: 110, height: 110)
                                                .overlay(
                                                    Image(systemName: "photo.slash")
                                                        .foregroundStyle(Color(.tertiaryLabel))
                                                )
                                        default:
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color(.tertiarySystemFill))
                                                .frame(width: 110, height: 110)
                                                .overlay(ProgressView())
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 6)
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    } header: {
                        Text("Damage Photos (\(photoURLs.count))")
                    }
                }

                // ── Reporter ──────────────────────────────────────
                Section("Reported By") {
                    LabeledContent("Driver", value: report.driverName)
                    let lic = driverProfile?.licenseNumber ?? report.driverLicenseNumber
                    if let l = lic, !l.isEmpty { LabeledContent("Licence No.", value: l) }
                    if let email = driverProfile?.email { LabeledContent("Email", value: email) }
                    if let phone = driverProfile?.phone { LabeledContent("Phone", value: phone) }
                }

                // ── Vehicle Details ───────────────────────────────
                Section("Vehicle Details") {
                    LabeledContent("Make & Model",
                                   value: "\(vehicle?.make ?? "—") \(vehicle?.model ?? "")".trimmingCharacters(in: .whitespaces))
                    if let year = vehicle?.year {
                        LabeledContent("Year", value: "\(year)")
                    }
                    LabeledContent("Licence Plate", value: report.licensePlate)
                    if let type = vehicle?.vehicleType {
                        LabeledContent("Type", value: type.displayName)
                    }
                    if let cap = vehicle?.tankCapacity {
                        LabeledContent("Tank Capacity", value: String(format: "%.0f L", cap))
                    }
                    if let mil = vehicle?.mileage {
                        LabeledContent("Mileage", value: String(format: "%.0f km/L", mil))
                    }
                }

                // ── Last Trip ─────────────────────────────────────
                if let trip = lastTrip {
                    Section("Last Trip on This Vehicle") {
                        if let type = trip.orderType {
                            LabeledContent("Order Type", value: type.displayName)
                        }
                        if let status = trip.status {
                            HStack {
                                Text("Status")
                                Spacer()
                                Text(status.rawValue.capitalized)
                                    .fontWeight(.medium)
                                    .foregroundStyle(tripStatusColor(status))
                            }
                        }

                        // Pickup → Drop-off
                        if let pickup = lastTripRoute?.startLocation {
                            LabeledContent("Pickup", value: pickup)
                        }
                        if let dropoff = lastTripRoute?.endLocation {
                            LabeledContent("Drop-off", value: dropoff)
                        }

                        if let start = trip.startTime {
                            LabeledContent("Started",
                                           value: start.formatted(date: .abbreviated, time: .shortened))
                        }
                        if let end = trip.endTime {
                            LabeledContent("Ended",
                                           value: end.formatted(date: .abbreviated, time: .shortened))
                        }
                        if let dist = trip.distance {
                            LabeledContent("Distance", value: String(format: "%.1f km", dist))
                        }
                    }
                }

                // ── Last Driver (if different) ────────────────────
                if let driver = lastDriver {
                    Section("Last Driver on This Vehicle") {
                        LabeledContent("Name", value: driver.fullName)
                        if let lic = driver.licenseNumber, !lic.isEmpty {
                            LabeledContent("Licence No.", value: lic)
                        }
                        LabeledContent("Email", value: driver.email)
                        if let phone = driver.phone {
                            LabeledContent("Phone", value: phone)
                        }
                    }
                }

                // ── Assignment ────────────────────────────────────
                Section("Assignment") {
                    if let staffId = selectedStaffId,
                       let staff = viewModel.maintenanceStaff.first(where: { $0.id == staffId }) {
                        LabeledContent("Assigned To", value: staff.fullName)
                        HStack {
                            Text("Workload")
                            Spacer()
                            Text(viewModel.staffWorkloadStatus(staffId))
                                .foregroundStyle(viewModel.staffWorkloadColor(staffId))
                                .font(.footnote)
                        }
                    } else {
                        Text("Not yet assigned")
                            .foregroundStyle(Color.secondary)
                    }

                    Button {
                        showingAssignment = true
                    } label: {
                        Label(
                            selectedStaffId == nil ? "Assign to Maintenance Staff" : "Reassign",
                            systemImage: "person.badge.plus"
                        )
                        .foregroundStyle(Color.teal)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Issue Report")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                // Fetch the route for the last trip to show pickup → drop-off
                if let routeId = lastTrip?.routeId {
                    lastTripRoute = try? await RouteService.fetchRoute(id: routeId)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingAssignment) {
                MaintenanceAssignmentSheet(
                    vehicleName: "\(vehicle?.make ?? "") \(vehicle?.model ?? "")",
                    licensePlate: report.licensePlate,
                    severityLabel: report.severity.rawValue.capitalized,
                    severityColor: viewModel.severityColor(report.severity),
                    severityIcon: report.severity == .critical
                        ? "exclamationmark.triangle.fill"
                        : "exclamationmark.circle.fill",
                    issueTitle: "Reported Issue",
                    issueDescription: cleanDescription.isEmpty ? "No description." : cleanDescription,
                    recommendationTitle: "Category",
                    recommendationDescription: report.issueCategory,
                    maintenanceStaff: viewModel.maintenanceStaff
                ) { staffId, notes in
                    assignStaff(staffId)
                    let workOrderId = try await WorkOrderService.createWorkOrder(
                        vehicleId: report.vehicleId,
                        createdBy: nil,
                        assignedTo: staffId,
                        priority: report.severity == .critical ? .critical
                            : (report.severity == .high ? .high : .medium),
                        status: .open
                    )
                    let task = MaintenanceTask(
                        id: UUID(),
                        workOrderId: workOrderId,
                        vehicleId: report.vehicleId,
                        scheduledBy: nil,
                        assignedTo: staffId,
                        taskType: .repair,
                        description: "\(report.issueCategory): \(cleanDescription)"
                            + (notes.isEmpty ? "" : "\nNotes: \(notes)"),
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

    // MARK: - Helpers

    private func assignStaff(_ staffId: UUID?) {
        selectedStaffId = staffId
        viewModel.update(
            reportId: report.id,
            assignedTo: staffId,
            status: staffId == nil ? .open : .assigned
        )
    }

    private func tripStatusColor(_ status: TripStatus) -> Color {
        switch status {
        case .scheduled: return .blue
        case .active:    return .green
        case .completed: return Color(.tertiaryLabel)
        case .cancelled: return .red
        }
    }
}

// MARK: - Preview

#Preview {
    ReportDetailView(
        report: IssueReport(
            id: UUID(), vehicleId: UUID(), reportedBy: UUID(),
            vehicleName: "Tata Ace", licensePlate: "MH-12-AB-1234",
            driverName: "Ravi Kumar", driverLicenseNumber: "DL-9876",
            issueCategory: "Engine Problem", severity: .high,
            description: "Strange knocking sound from engine when accelerating above 60 km/h.\n\nLocation: On Highway\nDriveable: No ⚠️\nOdometer: 45230 km\nReported at: 29 May 2026, 9:57 PM",
            submittedAt: Date(), assignedTo: nil, status: .open
        ),
        viewModel: ReportsViewModel()
    )
}
