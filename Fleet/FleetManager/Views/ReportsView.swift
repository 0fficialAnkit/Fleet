import SwiftUI

enum ReportSectionTab: String, CaseIterable {
    case vehicles = "Vehicles"
    case maintenance = "Maintenance"
    case fuel = "Fuel"
}

// MARK: - Reports View
struct ReportsView: View {
    @State private var viewModel = ReportsViewModel()
    @State private var selectedReport: IssueReport?
    @State private var filterStatus: IssueReportStatus? = nil
    @State private var selectedTab: ReportSectionTab = .maintenance

    var filteredReports: [IssueReport] {
        guard let f = filterStatus else { return viewModel.reports }
        return viewModel.reports.filter { $0.status == f }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    Picker("Section", selection: $selectedTab) {
                        ForEach(ReportSectionTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    switch selectedTab {
                    case .maintenance:
                        List {
                            // Filter chips — right below the "Reports" title
                            Section {
                                filterChips
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                            .listSectionSeparator(.hidden)

                            // Reports list
                            Section {
                                reportsListContent
                            }
                            .listSectionSeparator(.hidden)
                        }
                        .refreshable { await viewModel.loadData() }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)

                    case .fuel:
                        FleetFuelAnalyticsView()

                    case .vehicles:
                        Spacer()
                    }
                }
            }
            .navigationTitle("Reports")
            .sheet(item: $selectedReport) { report in
                ReportDetailView(report: report, viewModel: viewModel)
            }
            .task {
                await viewModel.loadData()
                viewModel.setupRealtime()
            }
        }
    }

    // MARK: - Filter Chips
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterButton(title: "All", isSelected: filterStatus == nil) {
                    withAnimation(.easeInOut(duration: 0.2)) { filterStatus = nil }
                }
                ForEach(IssueReportStatus.allCases) { status in
                    FilterButton(title: status.rawValue, isSelected: filterStatus == status) {
                        withAnimation(.easeInOut(duration: 0.2)) { filterStatus = status }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - List Content
    @ViewBuilder
    private var reportsListContent: some View {
        if viewModel.isLoading && viewModel.reports.isEmpty {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .listRowBackground(Color.clear)
            .padding(.vertical, 40)
        } else if filteredReports.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "tray.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color(.quaternaryLabel))
                Text("No reports found")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .listRowBackground(Color.clear)
        } else {
            ForEach(filteredReports) { report in
                Button(action: { selectedReport = report }) {
                    ReportRowView(report: report, viewModel: viewModel)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Report Row Card
struct ReportRowView: View {
    let report: IssueReport
    let viewModel: ReportsViewModel

    private var timeAgo: String {
        let diff = Date().timeIntervalSince(report.submittedAt)
        if diff < 60    { return "Just now" }
        if diff < 3600  { return "\(Int(diff / 60))m ago" }
        if diff < 86400 { return "\(Int(diff / 3600))h ago" }
        return "\(Int(diff / 86400))d ago"
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {

            VStack(alignment: .leading, spacing: 10) {

                // Top row: vehicle name (left) + assignment status badge (right)
                HStack(alignment: .top) {
                    Text(report.vehicleName)
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                    Spacer()
                    StatusBadge(
                        text: report.status.rawValue,
                        color: report.status.color,
                        icon: report.status.icon
                    )
                }

                // License plate
                Text(report.licensePlate)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.teal)

                // Issue type + severity badges
                HStack(spacing: 6) {
                    StatusBadge(text: report.issueCategory, color: Color.blue)
                    StatusBadge(
                        text: report.severity.rawValue.capitalized,
                        color: viewModel.severityColor(report.severity)
                    )
                }

                // Driver info (left) + time ago (right)
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.caption2)
                                .foregroundStyle(Color(.tertiaryLabel))
                            Text(report.driverName)
                                .font(.subheadline)
                                .foregroundStyle(Color.secondary)
                        }
                        if let license = report.driverLicenseNumber, !license.isEmpty {
                            Text(license)
                                .font(.caption)
                                .foregroundStyle(Color(.tertiaryLabel))
                                .padding(.leading, 16)
                        }
                    }
                    Spacer()
                    Text(timeAgo)
                        .font(.caption)
                        .foregroundStyle(Color(.quaternaryLabel))
                }
            }

            // Chevron — vertically centered on the right
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    ReportsView()
}
