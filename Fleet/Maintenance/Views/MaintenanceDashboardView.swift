import SwiftUI
import Supabase

struct MaintenanceDashboardView: View {
    @Binding var selectedTab: Int
    var schedulerViewModel: MaintenanceSchedulerViewModel
    @State private var viewModel = MaintenanceDashboardViewModel()
    @State private var isShowingProfile = false
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.inventory.isEmpty {
                    ProgressView()
                        .tint(.brown)
                } else {
                    List {
                        // MARK: - Inventory Status Card
                        Section {
                            inventoryStatusCard
                        }

                        // MARK: - Upcoming Scheduled Tasks
                        upcomingMaintenanceSection

                        // MARK: - Priority Queue
                        priorityQueueSection
                    }
                    .refreshable { await viewModel.loadData() }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { isShowingProfile = true }) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(Color.brown)
                    }
                }
            }
            .navigationDestination(for: MaintenanceDestination.self) { destination in
                switch destination {
                case .scheduledWorkOrderDetail(let scheduledWO):
                    WorkOrderDetailSheet(workOrder: scheduledWO, viewModel: MaintenanceSchedulerViewModel())
                case .issueReportDetail(let report):
                    IssueReportDetailView(report: report)
                case .workOrderList(let filter, let assignedTo, let priority):
                    WorkOrderListView(initialFilter: filter, assignedUserId: assignedTo, priorityFilter: priority)
                }
            }
            .sheet(isPresented: $isShowingProfile) {
                MaintenanceProfileView()
                    .environment(authViewModel)
            }
            .task {
                viewModel.currentUserId = authViewModel.currentUser?.id
                await viewModel.loadData()
                viewModel.setupRealtime()
            }
        }
    }

    private var inventoryStatusCard: some View {
        ZStack {
            NavigationLink {
                InventoryView()
            } label: {
                EmptyView()
            }
            .opacity(0)

            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.brown.opacity(0.12))
                            .frame(width: 48, height: 48)
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(Color.brown)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Inventory Status")
                            .font(.title2.bold())
                            .foregroundStyle(Color.primary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(.tertiaryLabel))
                        .padding(.top, 4)
                }

                Divider()
                    .background(Color(.separator))
                    .padding(.vertical, 16)

                HStack(spacing: 8) {
                    MaintenanceStatPill(
                        value: viewModel.inventory.count,
                        label: "Total Parts",
                        color: Color.brown
                    )
                    MaintenanceStatPill(
                        value: viewModel.lowStockItemsCount,
                        label: "Low Stock",
                        color: Color.red
                    )
                    MaintenanceStatPillText(
                        value: viewModel.estimatedValueFormatted,
                        label: "Est. Value",
                        color: Color.green
                    )
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var upcomingMaintenanceSection: some View {
        Section {
            if viewModel.upcomingItems.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 32))
                            .foregroundStyle(Color(.tertiaryLabel))
                        Text("No upcoming tasks")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 24)
            } else {
                ForEach(viewModel.upcomingItems) { item in
                    if let destination = item.destination {
                        NavigationLink {
                            switch destination {
                            case .scheduledWorkOrderDetail(let scheduledWO):
                                WorkOrderDetailSheet(workOrder: scheduledWO, viewModel: MaintenanceSchedulerViewModel())
                            case .issueReportDetail(let report):
                                IssueReportDetailView(report: report)
                            case .workOrderList(let filter, let assignedTo, let priority):
                                WorkOrderListView(initialFilter: filter, assignedUserId: assignedTo, priorityFilter: priority)
                            }
                        } label: {
                            UpcomingMaintenanceRow(item: item)
                        }
                    } else {
                        UpcomingMaintenanceRow(item: item)
                    }
                }
            }
        } header: {
            Text("Upcoming Maintenance")
        }
    }

    // MARK: - Priority Queue Section

    private var priorityQueueSection: some View {
        Section {
            if viewModel.priorityQueueItems.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.green)
                        Text("No priority tasks")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 24)
            } else {
                ForEach(viewModel.priorityQueueItems) { item in
                    NavigationLink {
                        switch item {
                        case .workOrder(let wo):
                            WorkOrderDetailSheet(workOrder: viewModel.buildScheduledWO(wo), viewModel: MaintenanceSchedulerViewModel())
                        case .issueReport(let ir):
                            WorkOrderDetailSheet(workOrder: viewModel.buildScheduledWOFromIR(ir), viewModel: MaintenanceSchedulerViewModel())
                        }
                    } label: {
                        PriorityQueueRow(item: item, viewModel: viewModel)
                    }
                }
            }
        } header: {
            HStack {
                Text("Priority Queue")
                Spacer()
                if !viewModel.priorityQueueItems.isEmpty {
                    NavigationLink(value: MaintenanceDestination.workOrderList(filter: nil, assignedTo: viewModel.currentUserId, priority: nil)) {
                        HStack(spacing: 4) {
                            Text("View All")
                                .font(.caption.weight(.medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(Color.brown)
                        .textCase(.none)
                    }
                }
            }
        }
    }
}

// MARK: - Upcoming Maintenance Row (compact, native)
struct UpcomingMaintenanceRow: View {
    let item: UpcomingDisplayItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Tags
            HStack(spacing: 8) {
                Text(item.referenceId)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Text(item.assignmentTag)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.brown)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.brown.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Spacer()

                if let priorityLabel = item.priorityLabel, let priorityColor = item.priorityColor {
                    Text(priorityLabel.capitalized)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(priorityColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(priorityColor.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            // Title & Description
            VStack(alignment: .leading, spacing: 3) {
                Text(item.vehicleName)
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                Text(item.taskDescription)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(2)
            }

            // Meta Info
            HStack(spacing: 14) {
                HStack(spacing: 5) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("Est. \(item.estimatedDuration)")
                }
                HStack(spacing: 5) {
                    Image(systemName: "wrench.adjustable")
                        .font(.caption2)
                    Text(item.location)
                }
            }
            .font(.caption)
            .foregroundStyle(Color(.tertiaryLabel))
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Reusable Cards
struct DashboardCard: View {
    let title: String
    let value: String
    let icon: String
    let titleColor: Color
    let valueColor: Color
    let backgroundColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(titleColor)
                    .lineLimit(2)
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(titleColor)
            }

            Text(value)
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundColor(valueColor)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

    }
}

struct AvailablePartsCard: View {
    let percentage: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("AVAILABLE PARTS")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.gray)

                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(percentage)")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                    Text("%")
                        .font(.title3.bold())
                        .foregroundColor(.gray)
                }
            }
            Spacer()

            ZStack {
                Circle()
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 60, height: 60)
                Image(systemName: "shippingbox")
                    .font(.system(size: 24))
                    .foregroundColor(Color(red: 122/255, green: 140/255, blue: 158/255))
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

    }
}

// MARK: - Maintenance Stat Pill (matches Fleet Manager style)
struct MaintenanceStatPill: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Text("\(value)")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.primary)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(color.opacity(0.25), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Maintenance Stat Pill (Text variant for string values)
struct MaintenanceStatPillText: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.primary)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(color.opacity(0.25), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Priority Queue Row (native list style)
struct PriorityQueueRow: View {
    let item: UnifiedMaintenanceItem
    let viewModel: MaintenanceDashboardViewModel

    var iconName: String {
        switch item {
        case .issueReport: return "exclamationmark.triangle.fill"
        case .workOrder: return "wrench.and.screwdriver.fill"
        }
    }

    var priorityColor: Color {
        switch item.unifiedPriority {
        case .critical, .high: return Color.red
        case .medium: return Color.blue
        case .low: return Color.secondary
        case nil: return Color.secondary
        }
    }

    var priorityLabel: String {
        switch item.unifiedPriority {
        case .critical: return "CRITICAL"
        case .high: return "HIGH"
        case .medium: return "MED"
        case .low: return "LOW"
        case nil: return "NONE"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(priorityColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: iconName)
                    .font(.system(size: 18))
                    .foregroundColor(priorityColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(viewModel.vehiclePlate(for: item.vehicleId))
                    .font(.body.bold())
                    .foregroundStyle(Color.primary)

                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(priorityLabel)
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(priorityColor.opacity(0.12))
                .foregroundColor(priorityColor)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    MaintenanceDashboardView(
        selectedTab: .constant(0),
        schedulerViewModel: MaintenanceSchedulerViewModel()
    )
    .environment(AuthViewModel())
}