import SwiftUI
internal import Auth

enum ReportSectionTab: String, CaseIterable {
    case vehicles    = "Vehicles"
    case maintenance = "Maintenance"
}

// MARK: - Reports View

struct ReportsView: View {

    @State private var viewModel    = ReportsViewModel()
    @State private var selectedReport: IssueReport?
    @State private var selectedTab: ReportSectionTab = .vehicles
    @Environment(AuthViewModel.self) private var authViewModel

    // Per-tab severity filter (Vehicles tab)
    @State private var vehicleSeverityFilter: DefectSeverity? = nil
    // Per-tab status filter (Maintenance tab)
    @State private var maintenanceStatusFilter: IssueReportStatus? = nil

    // ── Vehicle reports: open, not yet assigned ──────────────────
    var vehicleReports: [IssueReport] {
        let base = viewModel.reports.filter { $0.status == .open }
        let filtered = vehicleSeverityFilter == nil
            ? base
            : base.filter { $0.severity == vehicleSeverityFilter }
        return filtered.sorted { $0.submittedAt < $1.submittedAt }
    }

    // ── Maintenance reports: assigned / in-progress / resolved ───
    var maintenanceReports: [IssueReport] {
        let base = viewModel.reports.filter {
            $0.status == .assigned || $0.status == .inProgress || $0.status == .resolved
        }
        let filtered = maintenanceStatusFilter == nil
            ? base
            : base.filter { $0.status == maintenanceStatusFilter }
        // Most recently assigned first — use assignedAt; fall back to submittedAt if not set
        return filtered.sorted {
            ($0.assignedAt ?? $0.submittedAt) > ($1.assignedAt ?? $1.submittedAt)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Tab picker
                    Picker("Section", selection: $selectedTab) {
                        ForEach(ReportSectionTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    switch selectedTab {

                    case .vehicles:
                        reportList(
                            reports: vehicleReports,
                            emptyIcon: "tray",
                            emptyTitle: "No open alerts",
                            emptySubtitle: "All driver-submitted vehicle issues will appear here."
                        )

                    case .maintenance:
                        reportList(
                            reports: maintenanceReports,
                            emptyIcon: "wrench.and.screwdriver",
                            emptyTitle: "No maintenance alerts",
                            emptySubtitle: "Assign a vehicle report to maintenance to see it here."
                        )
                    }
                }
            }
            .navigationTitle("Alerts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if selectedTab == .vehicles {
                        Menu {
                            Picker("Severity", selection: $vehicleSeverityFilter) {
                                Text("All").tag(nil as DefectSeverity?)
                                ForEach([DefectSeverity.low, .medium, .high, .critical], id: \.self) { severity in
                                    Text(severity.rawValue.capitalized).tag(severity as DefectSeverity?)
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease")
                        }
                    } else if selectedTab == .maintenance {
                        Menu {
                            Picker("Status", selection: $maintenanceStatusFilter) {
                                Text("All").tag(nil as IssueReportStatus?)
                                ForEach([IssueReportStatus.assigned, .inProgress, .resolved], id: \.self) { status in
                                    Text(status.rawValue).tag(status as IssueReportStatus?)
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease")
                        }
                    }
                }
            }
            .sheet(item: $selectedReport) { report in
                ReportDetailView(report: report, viewModel: viewModel)
            }
            .task {
                // adminId is set via onChange below
            }
            .onChange(of: authViewModel.currentUser?.id, initial: true) { _, _ in
                guard let adminId = authViewModel.currentUserId else { return }
                viewModel.adminId = adminId
                Task {
                    await viewModel.loadData()
                    viewModel.setupRealtime()
                }
            }
            .refreshable { await viewModel.loadData() }
        }
    }

    // MARK: - Shared List Builder

    private func reportList(
        reports: [IssueReport],
        emptyIcon: String,
        emptyTitle: String,
        emptySubtitle: String
    ) -> some View {
        List {


            Section {
                if viewModel.isLoading && viewModel.reports.isEmpty {
                    HStack { Spacer(); ProgressView(); Spacer() }
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 40)
                } else if reports.isEmpty {
                    if #available(iOS 17.0, *) {
                        ContentUnavailableView(
                            emptyTitle,
                            systemImage: emptyIcon,
                            description: Text(emptySubtitle)
                        )
                        .listRowBackground(Color.clear)
                    } else {
                        emptyState(icon: emptyIcon, title: emptyTitle, subtitle: emptySubtitle)
                    }
                } else {
                    ForEach(reports) { report in
                        Button { selectedReport = report } label: {
                            ReportRowView(report: report, viewModel: viewModel, context: selectedTab)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listSectionSeparator(.hidden)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }


    // MARK: - Empty State

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(Color(.tertiaryLabel))
            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(Color.secondary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color(.tertiaryLabel))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .listRowBackground(Color.clear)
    }
}

// MARK: - Report Row Card

struct ReportRowView: View {
    let report: IssueReport
    let viewModel: ReportsViewModel
    var context: ReportSectionTab = .vehicles

    // Vehicles tab: time since report was submitted
    private var reportedTimeAgo: String {
        timeAgo(from: report.submittedAt)
    }

    // Name of the maintenance staff this is assigned to (nil if unassigned)
    private var assignedStaffName: String? {
        guard let id = report.assignedTo else { return nil }
        return viewModel.maintenanceStaff.first(where: { $0.id == id })?.fullName
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 10) {

                // Vehicle + badge
                // Open → show severity (Critical/High/Medium/Low)
                // Assigned / In Progress / Resolved → show workflow status
                HStack(alignment: .top) {
                    Text(report.vehicleName)
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                    Spacer()
                    if report.status == .open {
                        StatusBadge(
                            text: report.severity.rawValue.capitalized,
                            color: viewModel.severityColor(report.severity)
                        )
                    } else {
                        StatusBadge(
                            text: report.status.rawValue,
                            color: report.status.color,
                            icon: report.status.icon
                        )
                    }
                }

                // Licence plate (monospaced)
                Text(report.licensePlate)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.secondary)

                // Category always shown.
                // Severity shown here only when top-right badge is showing status (not severity).
                HStack(spacing: 6) {
                    StatusBadge(text: report.issueCategory, color: Color.blue)
                    if report.status != .open {
                        StatusBadge(
                            text: report.severity.rawValue.capitalized,
                            color: viewModel.severityColor(report.severity)
                        )
                    }
                }

                // Bottom row — changes by context
                HStack(alignment: .bottom) {
                    if context == .maintenance, let staffName = assignedStaffName {
                        // Maintenance: show who it's assigned to
                        HStack(spacing: 4) {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .font(.caption2)
                                .foregroundStyle(Color(.tertiaryLabel))
                            Text(staffName)
                                .font(.subheadline)
                                .foregroundStyle(Color.secondary)
                        }
                    } else {
                        // Vehicles: show who reported it
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.caption2)
                                .foregroundStyle(Color(.tertiaryLabel))
                            Text(report.driverName)
                                .font(.subheadline)
                                .foregroundStyle(Color.secondary)
                        }
                        Spacer()
                        Text(reportedTimeAgo)
                            .font(.caption)
                            .foregroundStyle(Color(.quaternaryLabel))
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .padding(.vertical, 6)
    }

    private func timeAgo(from date: Date) -> String {
        let diff = Date().timeIntervalSince(date)
        if diff < 60    { return "Just now" }
        if diff < 3600  { return "\(Int(diff / 60))m ago" }
        if diff < 86400 { return "\(Int(diff / 3600))h ago" }
        return "\(Int(diff / 86400))d ago"
    }
}

#Preview {
    ReportsView()
}
