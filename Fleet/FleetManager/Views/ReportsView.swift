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
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        summaryCards
                        filterChips
                        reportsList
                    }
                    .padding(.vertical, 16)
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
        HStack(spacing: 16) {
            summaryCard(label: "Open",     count: viewModel.openCount,     color: Color.red,  icon: "exclamationmark.circle.fill")
            summaryCard(label: "Active",   count: viewModel.assignedCount, color: Color.yellow, icon: "wrench.and.screwdriver.fill")
            summaryCard(label: "Resolved", count: viewModel.resolvedCount, color: Color.green, icon: "checkmark.circle.fill")
        }
        .padding(.horizontal, 16)
    }

    private func summaryCard(label: String, count: Int, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text("\(count)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)

            Text(label)
                .font(.system(size: , weight: .regular, design: .rounded))
                .foregroundStyle(Color(UIColor.tertiaryLabel))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
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
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Reports List
    private var reportsList: some View {
        LazyVStack(spacing: 16) {
            if filteredReports.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tray.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color(UIColor.quaternaryLabel))
                    Text("No reports found")
                        .font(.system(size: , weight: .medium, design: .rounded))
                        .foregroundStyle(Color.secondary)
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
        .padding(.horizontal, 16)
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
        VStack(alignment: .leading, spacing: 16) {
            // Top row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.vehicleName)
                        .font(.system(size: , weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.primary)
                    Text(report.licensePlate)
                        .font(.system(size: , weight: .regular, design: .rounded))
                        .foregroundStyle(Color.blue)
                }
                Spacer()
                StatusBadge(
                    text: report.status.rawValue,
                    color: report.status.color,
                    icon: report.status.icon
                )
            }

            // Category + severity
            HStack(spacing: 8) {
                StatusBadge(text: report.issueCategory, color: Color.blue)
                StatusBadge(
                    text: report.severity.rawValue.capitalized,
                    color: viewModel.severityColor(report.severity)
                )
            }

            // Description preview
            Text(report.description)
                .font(.system(size: , weight: .regular, design: .rounded))
                .foregroundStyle(Color.secondary)
                .lineLimit(2)

            // Footer
            HStack {
                Label(report.driverName, systemImage: "steeringwheel")
                    .font(.system(size: , weight: .regular, design: .rounded))
                    .foregroundStyle(Color(UIColor.tertiaryLabel))
                Spacer()
                if let assignedId = report.assignedTo {
                    Label(viewModel.staffName(assignedId), systemImage: "wrench.fill")
                        .font(.system(size: , weight: .regular, design: .rounded))
                        .foregroundStyle(Color.yellow)
                } else {
                    Text("Unassigned")
                        .font(.system(size: , weight: .regular, design: .rounded))
                        .foregroundStyle(Color(UIColor.quaternaryLabel))
                }
                Text("·")
                    .foregroundStyle(Color(UIColor.quaternaryLabel))
                Text(timeAgo)
                    .font(.system(size: , weight: .regular, design: .rounded))
                    .foregroundStyle(Color(UIColor.quaternaryLabel))
            }
        }
        .padding(16)
        .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(report.status == .open ? Color.red.opacity(0.25) : Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: 20))
    }
}



#Preview {
    ReportsView()
}
