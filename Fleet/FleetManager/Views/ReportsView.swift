import SwiftUI

// MARK: - Reports View (main list)
struct ReportsView: View {
    @State private var viewModel = ReportsViewModel()
    @State private var selectedReport: IssueReport?
    @State private var filterStatus: IssueReportStatus? = nil

    var filteredReports: [IssueReport] {
        guard let f = filterStatus else { return viewModel.reports }
        return viewModel.reports.filter { $0.status == f }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: themeModel.spacingLG) {
                        summaryCards
                        filterChips
                        reportsList
                    }
                    .padding(.vertical, themeModel.spacingMD)
                }
            }
            .navigationTitle("Issue Reports")
            .sheet(item: $selectedReport) { report in
                ReportDetailView(report: report, viewModel: viewModel)
            }
            .task {
                await viewModel.loadData()
                viewModel.setupRealtime()
            }
        }
    }

    // MARK: - Summary Cards
    private var summaryCards: some View {
        HStack(spacing: themeModel.spacingMD) {
            summaryCard(label: "Open",     count: viewModel.openCount,     color: themeModel.danger,  icon: "exclamationmark.circle.fill")
            summaryCard(label: "Active",   count: viewModel.assignedCount, color: themeModel.warning, icon: "wrench.and.screwdriver.fill")
            summaryCard(label: "Resolved", count: viewModel.resolvedCount, color: themeModel.success, icon: "checkmark.circle.fill")
        }
        .padding(.horizontal, themeModel.spacingMD)
    }

    private func summaryCard(label: String, count: Int, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: themeModel.spacingSM) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusXS, style: .continuous))

            Text("\(count)")
                .font(themeModel.title(22))
                .foregroundStyle(themeModel.textPrimary)

            Text(label)
                .font(themeModel.caption())
                .foregroundStyle(themeModel.textTertiary)
        }
        .padding(themeModel.spacingMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
        )
        .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
    }

    // MARK: - Filter Chips
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterButton(title: "All", isSelected: filterStatus == nil) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        filterStatus = nil
                    }
                }
                ForEach(IssueReportStatus.allCases) { status in
                    FilterButton(
                        title: status.rawValue,
                        isSelected: filterStatus == status
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            filterStatus = status
                        }
                    }
                }
            }
            .padding(.horizontal, themeModel.spacingMD)
        }
        .padding(.vertical, themeModel.spacingSM)
    }

    // MARK: - Reports List
    private var reportsList: some View {
        LazyVStack(spacing: themeModel.spacingMD) {
            if filteredReports.isEmpty {
                VStack(spacing: themeModel.spacingMD) {
                    Image(systemName: "tray.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(themeModel.textDisabled)
                    Text("No reports found")
                        .font(themeModel.bodyMedium())
                        .foregroundStyle(themeModel.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            } else {
                ForEach(filteredReports) { report in
                    ReportRowView(report: report, viewModel: viewModel)
                        .onTapGesture { selectedReport = report }
                }
            }
        }
        .padding(.horizontal, themeModel.spacingMD)
    }
}

// MARK: - Report Row
struct ReportRowView: View {
    let report: IssueReport
    let viewModel: ReportsViewModel

    private var timeAgo: String {
        let diff = Date().timeIntervalSince(report.submittedAt)
        if diff < 3600 { return "\(Int(diff / 60))m ago" }
        if diff < 86400 { return "\(Int(diff / 3600))h ago" }
        return "\(Int(diff / 86400))d ago"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
            // Top row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.vehicleName)
                        .font(themeModel.headline())
                        .foregroundStyle(themeModel.textPrimary)
                    Text(report.licensePlate)
                        .font(themeModel.caption())
                        .foregroundStyle(themeModel.accent)
                }
                Spacer()
                StatusBadge(
                    text: report.status.rawValue,
                    color: report.status.color,
                    icon: report.status.icon
                )
            }

            // Category + severity
            HStack(spacing: themeModel.spacingSM) {
                StatusBadge(text: report.issueCategory, color: themeModel.info)
                StatusBadge(
                    text: report.severity.rawValue.capitalized,
                    color: viewModel.severityColor(report.severity)
                )
            }

            // Description preview
            Text(report.description)
                .font(themeModel.body())
                .foregroundStyle(themeModel.textSecondary)
                .lineLimit(2)

            // Footer
            HStack {
                Label(report.driverName, systemImage: "steeringwheel")
                    .font(themeModel.caption())
                    .foregroundStyle(themeModel.textTertiary)
                Spacer()
                if let assignedId = report.assignedTo {
                    Label(viewModel.staffName(assignedId), systemImage: "wrench.fill")
                        .font(themeModel.caption())
                        .foregroundStyle(themeModel.warning)
                } else {
                    Text("Unassigned")
                        .font(themeModel.caption())
                        .foregroundStyle(themeModel.textDisabled)
                }
                Text("·")
                    .foregroundStyle(themeModel.textDisabled)
                Text(timeAgo)
                    .font(themeModel.caption())
                    .foregroundStyle(themeModel.textDisabled)
            }
        }
        .padding(themeModel.spacingMD)
        .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                .stroke(report.status == .open ? themeModel.danger.opacity(0.25) : Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: themeModel.radiusLG))
    }
}



#Preview {
    ReportsView()
}
