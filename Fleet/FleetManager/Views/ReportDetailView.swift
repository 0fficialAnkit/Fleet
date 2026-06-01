import SwiftUI
import UIKit

struct ReportDetailView: View {

    let report: IssueReport
    @State var viewModel: ReportsViewModel
    @State private var selectedStaffId: UUID?
    @State private var isAssigning = false
    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    @Environment(\.dismiss) private var dismiss

    // Track original assignment to detect changes on Done
    private let originalStaffId: UUID?

    init(report: IssueReport, viewModel: ReportsViewModel) {
        self.report       = report
        self.viewModel    = viewModel
        self.originalStaffId = report.assignedTo
        _selectedStaffId  = State(initialValue: report.assignedTo)
    }

    /// True when the report is in progress or resolved — reassignment is blocked.
    private var isLocked: Bool {
        report.status == .inProgress || report.status == .resolved
    }

    private var assignmentChanged: Bool {
        !isLocked && selectedStaffId != originalStaffId && selectedStaffId != nil
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
                Section {
                    if isLocked {
                        // Read-only when task is already active or resolved
                        if let staffId = selectedStaffId,
                           let staff = viewModel.maintenanceStaff.first(where: { $0.id == staffId }) {
                            LabeledContent("Assigned To", value: staff.fullName)
                        } else {
                            LabeledContent("Assigned To", value: "Not Assigned")
                        }

                        HStack(spacing: 6) {
                            Image(systemName: report.status == .resolved
                                  ? "checkmark.seal.fill" : "wrench.and.screwdriver.fill")
                                .font(.caption)
                                .foregroundStyle(report.status == .resolved ? Color.green : Color.blue)
                            Text(report.status == .resolved
                                 ? "Task resolved — reassignment not allowed."
                                 : "Task in progress — reassignment not allowed.")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                    } else if viewModel.maintenanceStaff.isEmpty {
                        Text("No maintenance staff available")
                            .foregroundStyle(Color.secondary)
                    } else {
                        Picker("Assign To", selection: $selectedStaffId) {
                            Text("Not Assigned").tag(nil as UUID?)
                            ForEach(viewModel.maintenanceStaff, id: \.id) { staff in
                                Text(staff.fullName).tag(staff.id as UUID?)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Color.primary)

                        if let staffId = selectedStaffId {
                            HStack {
                                Text("Workload")
                                Spacer()
                                Text(viewModel.staffWorkloadStatus(staffId))
                                    .foregroundStyle(viewModel.staffWorkloadColor(staffId))
                                    .font(.footnote)
                            }
                        }
                    }
                } header: {
                    Text("Assign to Maintenance")
                } footer: {
                    if !isLocked && assignmentChanged {
                        Text("Tap Done to confirm assignment and notify the maintenance staff.")
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
                ToolbarItemGroup(placement: .topBarTrailing) {
                    // Export / Share — dropdown menu anchored to the button
                    Menu {
                        Button {
                            export(format: .pdf)
                        } label: {
                            Label("Export as PDF", systemImage: "doc.richtext")
                        }
                        Button {
                            export(format: .csv)
                        } label: {
                            Label("Export as CSV", systemImage: "tablecells")
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Color.primary)
                    }

                    // Done / Assign
                    if isAssigning {
                        ProgressView()
                    } else {
                        Button("Done") { handleDone() }
                            .fontWeight(.semibold)
                            .foregroundStyle(assignmentChanged ? Color.teal : Color.primary)
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    // MARK: - Helpers

    private func handleDone() {
        // Blocked when task is already active or resolved
        guard !isLocked else { dismiss(); return }

        // If staff was newly selected, create work order + task then dismiss
        if assignmentChanged, let staffId = selectedStaffId {
            isAssigning = true
            Task {
                do {
                    // 1. Update report status
                    viewModel.update(reportId: report.id, assignedTo: staffId, status: .assigned)

                    // 2. Create work order
                    let workOrderId = try await WorkOrderService.createWorkOrder(
                        vehicleId: report.vehicleId,
                        createdBy: nil,
                        assignedTo: staffId,
                        priority: report.severity == .critical ? .critical
                            : (report.severity == .high ? .high : .medium),
                        status: .open
                    )

                    // 3. Create maintenance task
                    let task = MaintenanceTask(
                        id: UUID(),
                        workOrderId: workOrderId,
                        vehicleId: report.vehicleId,
                        scheduledBy: nil,
                        assignedTo: staffId,
                        taskType: .repair,
                        description: "\(report.issueCategory): \(cleanDescription)",
                        scheduledDate: Date(),
                        targetMileage: nil,
                        serviceIntervalMonths: nil,
                        scheduleType: .date,
                        status: .pending
                    )
                    try await MaintenanceTaskService.createTask(task)

                    // 4. Notify maintenance staff
                    let notification = Notification(
                        id: UUID(),
                        userId: staffId,
                        title: "New Task Assigned",
                        message: "\(report.issueCategory) on \(report.vehicleName) (\(report.licensePlate)) assigned to you.",
                        type: .maintenance,
                        isRead: false,
                        createdAt: Date()
                    )
                    try? await NotificationService.createNotification(notification)

                } catch {
                    print("[ReportDetailView] Assignment error: \(error)")
                }
                await MainActor.run {
                    isAssigning = false
                    dismiss()
                }
            }
        } else {
            dismiss()
        }
    }

    private func tripStatusColor(_ status: TripStatus) -> Color {
        switch status {
        case .scheduled: return .blue
        case .active:    return .green
        case .completed: return Color(.tertiaryLabel)
        case .cancelled: return .red
        }
    }

    // MARK: - Export

    enum ExportFormat { case csv, pdf }

    private func export(format: ExportFormat) {
        let fileName = "IssueReport_\(report.id.uuidString.prefix(8))"
        let tmpDir   = FileManager.default.temporaryDirectory

        switch format {
        case .csv:
            let data = buildCSV().data(using: .utf8) ?? Data()
            let url  = tmpDir.appendingPathComponent("\(fileName).csv")
            try? data.write(to: url)
            exportURL = url

        case .pdf:
            let url = tmpDir.appendingPathComponent("\(fileName).pdf")
            buildPDF(to: url)
            exportURL = url
        }

        showingShareSheet = true
    }

    // MARK: CSV Builder

    private func buildCSV() -> String {
        var rows: [(String, String)] = []

        rows.append(("Report ID",   report.id.uuidString.prefix(8).uppercased() + ""))
        rows.append(("Vehicle",     report.vehicleName))
        rows.append(("Licence Plate", report.licensePlate))
        if let type = vehicle?.vehicleType { rows.append(("Vehicle Type", type.displayName)) }
        if let year = vehicle?.year        { rows.append(("Year",         "\(year)")) }
        if let cap  = vehicle?.tankCapacity { rows.append(("Tank Capacity", String(format: "%.0f L", cap))) }
        if let mil  = vehicle?.mileage     { rows.append(("Mileage",      String(format: "%.0f km/L", mil))) }
        rows.append(("",            ""))
        rows.append(("Category",    report.issueCategory))
        rows.append(("Severity",    report.severity.rawValue.capitalized))
        rows.append(("Status",      report.status.rawValue))
        rows.append(("Reported",    report.submittedAt.formatted(date: .long, time: .shortened)))
        if let loc = meta["Location"]    { rows.append(("Where Noticed", loc)) }
        if let rat = meta["Reported at"] { rows.append(("Time of Incident", rat)) }
        if let drv = meta["Driveable"]   { rows.append(("Vehicle Driveable", drv)) }
        if !cleanDescription.isEmpty     { rows.append(("Description", cleanDescription.replacingOccurrences(of: "\n", with: " "))) }
        rows.append(("",            ""))
        rows.append(("Driver",      report.driverName))
        if let lic = driverProfile?.licenseNumber ?? report.driverLicenseNumber { rows.append(("Driver Licence", lic)) }
        if let email = driverProfile?.email { rows.append(("Driver Email", email)) }
        if let phone = driverProfile?.phone { rows.append(("Driver Phone", phone)) }
        if let trip = lastTrip {
            rows.append(("", ""))
            if let t = trip.orderType      { rows.append(("Last Trip Type",    t.displayName)) }
            if let s = trip.startTime      { rows.append(("Last Trip Started", s.formatted(date: .abbreviated, time: .shortened))) }
            if let e = trip.endTime        { rows.append(("Last Trip Ended",   e.formatted(date: .abbreviated, time: .shortened))) }
            if let d = trip.distance       { rows.append(("Last Trip Distance", String(format: "%.1f km", d))) }
            if let p = lastTripRoute?.startLocation { rows.append(("Pickup",   p)) }
            if let d2 = lastTripRoute?.endLocation  { rows.append(("Drop-off", d2)) }
        }
        if let staffId = selectedStaffId,
           let staff   = viewModel.maintenanceStaff.first(where: { $0.id == staffId }) {
            rows.append(("", ""))
            rows.append(("Assigned To", staff.fullName))
        }

        let header = "Issue Report,Generated: \(Date().formatted(date: .long, time: .shortened))\n\nField,Value\n"
        let body   = rows.map { "\($0.0),\"\($0.1.replacingOccurrences(of: "\"", with: "\"\""))\"" }.joined(separator: "\n")
        return header + body
    }

    // MARK: PDF Builder

    private func buildPDF(to url: URL) {
        let pageW: CGFloat = 595   // A4 width points
        let pageH: CGFloat = 842   // A4 height points
        let margin: CGFloat = 48
        let renderer  = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageW, height: pageH))

        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = margin

            func drawText(_ text: String, x: CGFloat = margin, font: UIFont, color: UIColor = .label, maxWidth: CGFloat? = nil) -> CGFloat {
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                let w    = maxWidth ?? (pageW - margin * 2)
                let rect = CGRect(x: x, y: y, width: w, height: 2000)
                let str  = NSString(string: text)
                let used = str.boundingRect(with: rect.size, options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
                str.draw(in: CGRect(x: x, y: y, width: w, height: used.height), withAttributes: attrs)
                return used.height + 4
            }

            func section(_ title: String) {
                y += 14
                let sepPath = UIBezierPath()
                sepPath.move(to: CGPoint(x: margin, y: y))
                sepPath.addLine(to: CGPoint(x: pageW - margin, y: y))
                UIColor.separator.setStroke(); sepPath.lineWidth = 0.5; sepPath.stroke()
                y += 6
                y += drawText(title.uppercased(), font: .systemFont(ofSize: 10, weight: .semibold), color: .secondaryLabel)
                y += 2
            }

            func row(_ label: String, _ value: String) {
                if y > pageH - margin * 2 { ctx.beginPage(); y = margin }
                let labelFont = UIFont.systemFont(ofSize: 12, weight: .regular)
                let valueFont = UIFont.systemFont(ofSize: 12, weight: .medium)
                let lW: CGFloat = 180
                let labelH = drawText(label, font: labelFont, color: .secondaryLabel, maxWidth: lW)
                let valueX = margin + lW + 8
                let valueH = drawText(value, x: valueX, font: valueFont, maxWidth: pageW - margin - valueX)
                y += max(labelH, valueH)
            }

            // Title
            y += drawText("Issue Report", font: .systemFont(ofSize: 22, weight: .bold))
            y += drawText("Generated \(Date().formatted(date: .long, time: .shortened))",
                          font: .systemFont(ofSize: 11), color: .secondaryLabel)
            y += 4

            // Vehicle
            section("Vehicle")
            row("Vehicle",        report.vehicleName)
            row("Licence Plate",  report.licensePlate)
            if let t = vehicle?.vehicleType  { row("Type",          t.displayName) }
            if let yr = vehicle?.year        { row("Year",          "\(yr)") }
            if let cap = vehicle?.tankCapacity { row("Tank Capacity", String(format: "%.0f L", cap)) }
            if let mil = vehicle?.mileage    { row("Mileage",       String(format: "%.0f km/L", mil)) }

            // Issue
            section("Issue Details")
            row("Report ID",  report.id.uuidString.prefix(8).uppercased() + "")
            row("Category",   report.issueCategory)
            row("Severity",   report.severity.rawValue.capitalized)
            row("Status",     report.status.rawValue)
            row("Reported",   report.submittedAt.formatted(date: .long, time: .shortened))
            if let loc = meta["Location"]    { row("Where Noticed",    loc) }
            if let rat = meta["Reported at"] { row("Time of Incident", rat) }
            if let drv = meta["Driveable"]   { row("Vehicle Driveable", drv) }
            if !cleanDescription.isEmpty     {
                section("Description")
                y += drawText(cleanDescription, font: .systemFont(ofSize: 12))
            }

            // Reporter
            section("Reported By")
            row("Driver",  report.driverName)
            if let lic   = driverProfile?.licenseNumber ?? report.driverLicenseNumber { row("Licence No.", lic) }
            if let email = driverProfile?.email { row("Email", email) }
            if let phone = driverProfile?.phone { row("Phone", phone) }

            // Last trip
            if let trip = lastTrip {
                section("Last Trip on This Vehicle")
                if let t = trip.orderType  { row("Order Type", t.displayName) }
                if let p = lastTripRoute?.startLocation { row("Pickup",   p) }
                if let d = lastTripRoute?.endLocation   { row("Drop-off", d) }
                if let s = trip.startTime  { row("Started", s.formatted(date: .abbreviated, time: .shortened)) }
                if let e = trip.endTime    { row("Ended",   e.formatted(date: .abbreviated, time: .shortened)) }
                if let dist = trip.distance { row("Distance", String(format: "%.1f km", dist)) }
            }

            // Assignment
            section("Assignment")
            if let staffId = selectedStaffId,
               let staff   = viewModel.maintenanceStaff.first(where: { $0.id == staffId }) {
                row("Assigned To", staff.fullName)
            } else {
                row("Assigned To", "Not Assigned")
            }
        }

        try? data.write(to: url)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
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
