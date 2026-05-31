import SwiftUI

// MARK: - Report Detail View
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

    // MARK: - Computed lookups (all from already-loaded viewModel data)

    var vehicle: Vehicle? {
        viewModel.vehicle(for: report.vehicleId)
    }

    var driverProfile: Profile? {
        viewModel.profile(for: report.reportedBy)
    }

    var lastTrip: Trip? {
        viewModel.lastTrip(for: report.vehicleId)
    }

    /// Driver of the last trip (even if the same person who raised the report).
    var lastDriver: Profile? {
        guard let trip = lastTrip else { return nil }
        return viewModel.profile(for: trip.driverId)
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {

                // MARK: — Vehicle —
                Section("Vehicle") {
                    LabeledContent("Make",          value: vehicle?.make  ?? "—")
                    LabeledContent("Model",         value: vehicle?.model ?? "—")
                    LabeledContent("Year",          value: vehicle?.year.map { "\($0)" } ?? "—")
                    LabeledContent("License Plate", value: report.licensePlate)
                    if let vin = vehicle?.vin, !vin.isEmpty {
                        LabeledContent("VIN", value: vin)
                    }
                    if let type = vehicle?.vehicleType {
                        LabeledContent("Type", value: type.displayName)
                    }
                }

                // MARK: — Issue —
                Section("Issue") {
                    LabeledContent("Category", value: report.issueCategory)

                    HStack {
                        Text("Severity")
                            .foregroundStyle(Color.secondary)
                        Spacer()
                        StatusBadge(
                            text: report.severity.rawValue.capitalized,
                            color: viewModel.severityColor(report.severity)
                        )
                    }

                    HStack {
                        Text("Status")
                            .foregroundStyle(Color.secondary)
                        Spacer()
                        StatusBadge(
                            text: report.status.rawValue,
                            color: report.status.color,
                            icon: report.status.icon
                        )
                    }

                    if !report.description.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Description")
                                .font(.caption)
                                .foregroundStyle(Color(.tertiaryLabel))
                                .textCase(.uppercase)
                            Text(report.description)
                                .font(.body)
                                .foregroundStyle(Color.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 4)
                    }
                }

                // MARK: — Reported By —
                Section("Reported By") {
                    LabeledContent("Driver", value: report.driverName)

                    // Prefer the profile's license, fall back to the one we cached in IssueReport
                    let license = driverProfile?.licenseNumber ?? report.driverLicenseNumber
                    if let lic = license, !lic.isEmpty {
                        LabeledContent("License No.", value: lic)
                    }
                    if let email = driverProfile?.email {
                        LabeledContent("Email", value: email)
                    }
                    if let phone = driverProfile?.phone {
                        LabeledContent("Phone", value: phone)
                    }
                    LabeledContent(
                        "Reported On",
                        value: report.submittedAt.formatted(date: .long, time: .shortened)
                    )
                }

                // MARK: — Last Trip —
                if let trip = lastTrip {
                    Section("Last Trip") {
                        if let status = trip.status {
                            HStack {
                                Text("Status")
                                    .foregroundStyle(Color.secondary)
                                Spacer()
                                Text(status.rawValue.capitalized)
                                    .foregroundStyle(tripStatusColor(status))
                                    .fontWeight(.medium)
                            }
                        }
                        if let start = trip.startTime {
                            LabeledContent("Started", value: start.formatted(date: .abbreviated, time: .shortened))
                        }
                        if let end = trip.endTime {
                            LabeledContent("Ended", value: end.formatted(date: .abbreviated, time: .shortened))
                        }
                        if let dist = trip.distance {
                            LabeledContent("Distance", value: String(format: "%.1f km", dist))
                        }
                        if let orderType = trip.orderType {
                            LabeledContent("Order Type", value: orderType.displayName)
                        }
                    }
                }

                // MARK: — Last Driver —
                // Always shown when available, even if the same driver raised the report.
                if let driver = lastDriver {
                    Section("Last Driver") {
                        LabeledContent("Name", value: driver.fullName)
                        if let lic = driver.licenseNumber, !lic.isEmpty {
                            LabeledContent("License No.", value: lic)
                        }
                        LabeledContent("Email", value: driver.email)
                        if let phone = driver.phone {
                            LabeledContent("Phone", value: phone)
                        }
                    }
                }

                // MARK: — Assigned To —
                Section("Assigned To") {
                    if let staffId = selectedStaffId,
                       let staff = viewModel.maintenanceStaff.first(where: { $0.id == staffId }) {
                        LabeledContent("Staff", value: staff.fullName)
                        HStack {
                            Text("Workload")
                                .foregroundStyle(Color.secondary)
                            Spacer()
                            Text(viewModel.staffWorkloadStatus(staffId))
                                .foregroundStyle(viewModel.staffWorkloadColor(staffId))
                                .font(.footnote)
                        }
                    } else {
                        Text("Not yet assigned")
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
            .navigationTitle("Issue Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Done — dismiss the sheet
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.primary)
                }

                // Assign — open assignment sheet
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAssignment = true
                    } label: {
                        Label("Assign", systemImage: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingAssignment) {
                MaintenanceAssignmentSheet(
                    vehicleName: vehicle?.make ?? "" + (vehicle?.model ?? ""),
                    licensePlate: report.licensePlate,
                    severityLabel: report.severity.rawValue.capitalized,
                    severityColor: viewModel.severityColor(report.severity),
                    severityIcon: report.severity == .critical ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill",
                    issueTitle: "Reported Issue",
                    issueDescription: report.description.isEmpty ? "No description provided." : report.description,
                    recommendationTitle: "Category",
                    recommendationDescription: report.issueCategory,
                    maintenanceStaff: viewModel.maintenanceStaff
                ) { staffId, notes in
                    // Update Issue Report status
                    assignStaff(staffId)
                    
                    // Create Work Order
                    let workOrderId = try await WorkOrderService.createWorkOrder(
                        vehicleId: report.vehicleId,
                        createdBy: nil,
                        assignedTo: staffId,
                        priority: report.severity == .critical ? .critical : (report.severity == .high ? .high : .medium),
                        status: .open
                    )
                    
                    // Create Maintenance Task
                    let task = MaintenanceTask(
                        id: UUID(),
                        workOrderId: workOrderId,
                        vehicleId: report.vehicleId,
                        scheduledBy: nil,
                        assignedTo: staffId,
                        taskType: .repair,
                        description: "\(report.issueCategory): \(report.description)\(notes.isEmpty ? "" : "\nNotes: \(notes)")",
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

    // MARK: - Private Helpers

    private func assignStaff(_ staffId: UUID?) {
        selectedStaffId = staffId
        let newStatus: IssueReportStatus = (staffId == nil) ? .open : .assigned
        viewModel.update(reportId: report.id, assignedTo: staffId, status: newStatus)
    }

    private func tripStatusColor(_ status: TripStatus) -> Color {
        switch status {
        case .scheduled:  return Color.blue
        case .active:     return Color.green
        case .completed:  return Color(.tertiaryLabel)
        case .cancelled:  return Color.red
        }
    }
}

#Preview {
    ReportDetailView(
        report: IssueReport(
            id: UUID(),
            vehicleId: UUID(),
            reportedBy: UUID(),
            vehicleName: "Ford Transit",
            licensePlate: "CA-12345",
            driverName: "John Doe",
            driverLicenseNumber: "DL-98765",
            issueCategory: "Brakes",
            severity: .critical,
            description: "Front brake pads are worn down to the metal, causing grinding sound.",
            submittedAt: Date(),
            assignedTo: nil,
            status: .open
        ),
        viewModel: ReportsViewModel()
    )
}
