import SwiftUI

// MARK: - Reports View (main list)
struct ReportsView: View {
    @State private var viewModel = ReportsViewModel()
    @State private var selectedReport: IssueReport?
    @State private var filterStatus: IssueReportStatus? = nil
    
    @State private var isExporting = false

    var filteredReports: [IssueReport] {
        guard let f = filterStatus else { return viewModel.reports }
        return viewModel.reports.filter { $0.status == f }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            exportCSV()
                        } label: {
                            Label("Export CSV", systemImage: "tablecells.fill")
                        }
                        
                        Button {
                            Task {
                                await exportPDF()
                            }
                        } label: {
                            Label("Export PDF", systemImage: "doc.text.fill")
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.primary)
                    }
                }
            }
            .overlay {
                if isExporting {
                    ZStack {
                        Color.black.opacity(0.15)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                            Text("Generating Document...")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .fontWeight(.medium)
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.black.opacity(0.15), radius: 10, y: 5)
                    }
                }
            }
            .task {
                await viewModel.loadData()
                viewModel.setupRealtime()
            }
        }
    }
    
    private func exportCSV() {
        guard let url = CSVGenerator.generateCSV(from: filteredReports) else { return }
        ShareSheet.share(items: [url])
    }
    
    private func exportPDF() async {
        isExporting = true
        if let url = await PDFGenerator.generatePDF(from: filteredReports) {
            ShareSheet.share(items: [url])
        }
        isExporting = false
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
                .font(.title3.bold())
                .foregroundStyle(Color.primary)

            Text(label)
                .font(.footnote)
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

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
                        .foregroundStyle(Color(.quaternaryLabel))
                    Text("No reports found")
                        .font(.body.weight(.medium))
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
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                    Text(report.licensePlate)
                        .font(.footnote)
                        .foregroundStyle(Color.teal)
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
                .font(.body)
                .foregroundStyle(Color.secondary)
                .lineLimit(2)

            // Footer
            HStack {
                Label(report.driverName, systemImage: "steeringwheel")
                    .font(.footnote)
                    .foregroundStyle(Color(.tertiaryLabel))
                Spacer()
                if let assignedId = report.assignedTo {
                    Label(viewModel.staffName(assignedId), systemImage: "wrench.fill")
                        .font(.footnote)
                        .foregroundStyle(Color.yellow)
                } else {
                    Text("Unassigned")
                        .font(.footnote)
                        .foregroundStyle(Color(.quaternaryLabel))
                }
                Text("·")
                    .foregroundStyle(Color(.quaternaryLabel))
                Text(timeAgo)
                    .font(.footnote)
                    .foregroundStyle(Color(.quaternaryLabel))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ReportsView()
}