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
            HStack(spacing: themeModel.spacingSM) {
                filterChip(label: "All", status: nil)
                ForEach(IssueReportStatus.allCases) { status in
                    filterChip(label: status.rawValue, status: status)
                }
            }
            .padding(.horizontal, themeModel.spacingMD)
        }
    }

    private func filterChip(label: String, status: IssueReportStatus?) -> some View {
        let isSelected = filterStatus == status
        let color: Color = status?.color ?? themeModel.accent
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                filterStatus = isSelected ? nil : status
            }
        }) {
            Text(label)
                .font(themeModel.caption())
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? color : themeModel.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(isSelected ? color.opacity(0.15) : Color.white.opacity(0.05)))
                .overlay(Capsule().stroke(isSelected ? color.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
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

// MARK: - Report Detail View
struct ReportDetailView: View {
    let report: IssueReport
    @State var viewModel: ReportsViewModel

    @State private var selectedStaffId: UUID?
    @State private var selectedStatus: IssueReportStatus
    @State private var isSaved = false
    @Environment(\.dismiss) private var dismiss

    init(report: IssueReport, viewModel: ReportsViewModel) {
        self.report = report
        self.viewModel = viewModel
        _selectedStaffId = State(initialValue: report.assignedTo)
        _selectedStatus  = State(initialValue: report.status)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: themeModel.spacingLG) {
                        issueHeaderCard
                        assignmentCard
                        saveButton
                    }
                    .padding(themeModel.spacingMD)
                    .padding(.bottom, themeModel.spacingXXL)
                }
            }
            .navigationTitle("Report Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(themeModel.accent)
                }
            }
        }
    }

    // MARK: - Issue Header
    private var issueHeaderCard: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
            // Vehicle + badges
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.vehicleName)
                        .font(themeModel.title(20))
                        .foregroundStyle(themeModel.textPrimary)
                    Text(report.licensePlate)
                        .font(themeModel.caption())
                        .foregroundStyle(themeModel.accent)
                }
                Spacer()
                StatusBadge(
                    text: report.severity.rawValue.capitalized,
                    color: viewModel.severityColor(report.severity)
                )
            }

            // Category
            StatusBadge(text: report.issueCategory, color: themeModel.info, icon: "exclamationmark.triangle.fill")

            Divider().background(themeModel.divider)

            // Description
            Text(report.description)
                .font(themeModel.body())
                .foregroundStyle(themeModel.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider().background(themeModel.divider)

            // Meta
            HStack {
                Label(report.driverName, systemImage: "steeringwheel")
                    .font(themeModel.caption())
                    .foregroundStyle(themeModel.textTertiary)
                Spacer()
                Label(report.submittedAt.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                    .font(themeModel.caption())
                    .foregroundStyle(themeModel.textDisabled)
            }
        }
        .padding(themeModel.spacingMD)
        .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
        )
        .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
    }

    // MARK: - Assignment Card
    private var assignmentCard: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
            Label("Assign to Maintenance Staff", systemImage: "person.badge.plus")
                .font(themeModel.headline())
                .foregroundStyle(themeModel.textPrimary)

            VStack(spacing: themeModel.spacingSM) {
                // Unassigned option
                staffRow(id: nil, name: "Unassigned", subtitle: "No assignment")

                ForEach(viewModel.maintenanceStaff) { staff in
                    staffRow(id: staff.id, name: staff.fullName, subtitle: staff.email)
                }
            }
        }
        .padding(themeModel.spacingMD)
        .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
        )
        .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
    }

    private func staffRow(id: UUID?, name: String, subtitle: String) -> some View {
        let isSelected = selectedStaffId == id
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedStaffId = id
                if id != nil && selectedStatus == .open {
                    selectedStatus = .assigned
                } else if id == nil {
                    selectedStatus = .open
                }
            }
        }) {
            HStack(spacing: themeModel.spacingMD) {
                ZStack {
                    Circle()
                        .fill(isSelected ? themeModel.accent.opacity(0.15) : Color.white.opacity(0.05))
                        .frame(width: 40, height: 40)
                    Image(systemName: id == nil ? "person.slash.fill" : "person.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(isSelected ? themeModel.accent : themeModel.textSecondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(themeModel.bodyMedium())
                        .foregroundStyle(isSelected ? themeModel.textPrimary : themeModel.textSecondary)
                    Text(subtitle)
                        .font(themeModel.caption())
                        .foregroundStyle(themeModel.textDisabled)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(themeModel.accent)
                        .font(.system(size: 18))
                }
            }
            .padding(themeModel.spacingSM)
            .background(
                RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous)
                    .fill(isSelected ? themeModel.accent.opacity(0.08) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous)
                    .stroke(isSelected ? themeModel.accent.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: handleSave) {
            HStack(spacing: themeModel.spacingSM) {
                if isSaved {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Changes Saved")
                } else {
                    Image(systemName: "square.and.arrow.down.fill")
                    Text("Save Changes")
                }
            }
            .font(themeModel.bodyMedium())
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background {
                if isSaved {
                    themeModel.success
                } else {
                    LinearGradient(
                        colors: [themeModel.accent, themeModel.accent.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous))
            .shadow(color: themeModel.accent.opacity(0.3), radius: 12, y: 6)
            .animation(.easeInOut(duration: 0.3), value: isSaved)
        }
        .buttonStyle(.plain)
    }

    private func handleSave() {
        viewModel.update(reportId: report.id, assignedTo: selectedStaffId, status: selectedStatus)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { isSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
    }
}

#Preview {
    ReportsView()
}
