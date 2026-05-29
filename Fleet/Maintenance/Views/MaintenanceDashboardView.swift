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
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // MARK: - KPI Summary Card
                        // --- Inventory Status card ---
                        NavigationLink {
                            InventoryView()
                        } label: {
                            VStack(spacing: 0) {
                                HStack(alignment: .top, spacing: 16) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color.brown.opacity(0.12))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "shippingbox.fill")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundStyle(Color.brown)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Inventory Status")
                                            .font(.headline.bold())
                                            .foregroundStyle(Color.primary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color.secondary)
                                        .padding(.top, 4)
                                }
                                Divider()
                                    .padding(.vertical, 12)
                                HStack(spacing: 8) {
                                    MaintenanceStatPill(
                                        value: viewModel.availablePartsPercentage,
                                        label: "Available %",
                                        color: Color.green
                                    )
                                    MaintenanceStatPill(
                                        value: viewModel.lowStockItemsCount,
                                        label: "Low Stock",
                                        color: Color.red
                                    )
                                    MaintenanceStatPill(
                                        value: viewModel.inventory.count,
                                        label: "Total Parts",
                                        color: Color.brown
                                    )
                                }
                            }
                            .padding(16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)

                        // MARK: - Upcoming Scheduled Tasks
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Upcoming Maintenance")
                                .padding(.horizontal, 16)

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
                                VStack(spacing: 16) {
                                    ForEach(viewModel.upcomingItems) { item in
                                        UpcomingMaintenanceCard(item: item)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }

                        // MARK: - Priority Queue
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Priority Queue", action: "View All") {
                                // Navigate to all unified items, maybe workOrderList with priority filter
                            }
                            .padding(.horizontal, 16)

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
                                VStack(spacing: 16) {
                                    ForEach(viewModel.priorityQueueItems) { item in
                                        PriorityQueueCard(item: item, viewModel: viewModel)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }

                    }
                    .padding(.vertical, 16)
                }
                .refreshable { await viewModel.loadData() }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { isShowingProfile = true }) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 28, weight: .medium))
//                            .foregroundStyle(Color.brown)
                    }
                }
            }
            .navigationDestination(for: MaintenanceDestination.self) { destination in
                switch destination {
                case .workOrderDetail(let order):
                    WorkOrderDetailView(workOrder: order)
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
}

// MARK: - Upcoming Maintenance Card
struct UpcomingMaintenanceCard: View {
    let item: UpcomingDisplayItem

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Image Placeholder & Badge
            ZStack(alignment: .topLeading) {
                // Placeholder Image
                Rectangle()
                    .fill(Color(.tertiarySystemBackground))
                    .frame(height: 180)
                    .overlay(
                        Image(systemName: "box.truck.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Color(.tertiaryLabel).opacity(0.3))
                    )

                // Priority Badge
                if let priorityLabel = item.priorityLabel, let priorityColor = item.priorityColor {
                    Text(priorityLabel.capitalized)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(priorityColor)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(12)
                }
            }

            // MARK: - Content
            VStack(alignment: .leading, spacing: 12) {
                // Tags
                HStack(spacing: 8) {
                    Text(item.referenceId)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Text(item.assignmentTag)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.brown)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.brown.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                // Titles
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.vehicleName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.primary)

                    Text(item.taskDescription)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color.secondary)
                }

                // Meta Info
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                        Text("Est. \(item.estimatedDuration)")
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "wrench.adjustable")
                        Text(item.location)
                    }
                }
                .font(.system(size: 14))
                .foregroundStyle(Color.secondary)
                .padding(.vertical, 4)

                // Action Buttons
                VStack(spacing: 10) {
                    Button {
                        // Handle Start Action
                    } label: {
                        HStack {
                            Image(systemName: item.actionButtonIcon)
                            Text(item.actionButtonTitle)
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.brown)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    if let destination = item.destination {
                        NavigationLink(value: destination) {
                            Text("View Details")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(.opaqueSeparator), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.top, 4)
            }
            .padding(16)
            .background(Color(.systemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

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

// MARK: - Priority Queue Card
struct PriorityQueueCard: View {
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
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(priorityColor.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(priorityColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.vehiclePlate(for: item.vehicleId))
                    .font(.body.bold())
                    .foregroundStyle(Color.primary)

                Text(item.subtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 12) {
                Text(priorityLabel)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityColor.opacity(0.15))
                    .foregroundColor(priorityColor)
                    .clipShape(Capsule())

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(.tertiaryLabel))
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

    }
}

#Preview {
    MaintenanceDashboardView(
        selectedTab: .constant(0),
        schedulerViewModel: MaintenanceSchedulerViewModel()
    )
    .environment(AuthViewModel())
}