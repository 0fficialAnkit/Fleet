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
                if viewModel.isLoading && viewModel.inventory.isEmpty && viewModel.upcomingItems.isEmpty {
                    ProgressView()
                        .tint(.brown)
                } else {
                    List {
                        Section {
                            inventoryOverviewCard
                        }

                        upcomingMaintenanceSection
                    }
                    .refreshable { await viewModel.loadData() }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { isShowingProfile = true }) {
                        Image(systemName: "person.crop.circle")
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationDestination(for: MaintenanceDestination.self) { destination in
                switch destination {
                case .scheduledWorkOrderDetail(let scheduledWO):
                    WorkOrderDetailSheet(workOrder: scheduledWO, viewModel: MaintenanceSchedulerViewModel())
                case .issueReportDetail(let report):
                    WorkOrderDetailSheet(workOrder: viewModel.buildScheduledWOFromIR(report), viewModel: MaintenanceSchedulerViewModel())
                case .workOrderList(let filter, let assignedTo, let priority):
                    WorkOrderListView(initialFilter: filter, assignedUserId: assignedTo, priorityFilter: priority)
                }
            }
            .sheet(isPresented: $isShowingProfile) {
                MaintenanceProfileView()
                    .environment(authViewModel)
            }
            .onChange(of: authViewModel.currentUser?.id, initial: true) { _, newUserId in
                guard let userId = newUserId else { return }
                viewModel.currentUserId = userId
                Task {
                    await viewModel.loadData()
                    viewModel.setupRealtime()
                }
            }
        }
    }

    // MARK: - Inventory Overview Card

    private var inventoryOverviewCard: some View {
        ZStack {
            NavigationLink(destination: InventoryView()) { EmptyView() }
                .opacity(0)

            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.brown.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: "shippingbox")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.brown)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Inventory")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(viewModel.inventory.count) parts")
                            .font(.headline)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(.tertiaryLabel))
                }

                Divider().padding(.vertical, 14)

                HStack(spacing: 0) {
                    mKpiCell("\(viewModel.inventory.count)", "Total", .brown)
                    Divider().frame(height: 36)
                    mKpiCell("\(viewModel.lowStockItemsCount)", "Low Stock", .red)
                    Divider().frame(height: 36)
                    mKpiCell(viewModel.estimatedValueFormatted, "Est. Value", .green)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Upcoming Maintenance Section

    private var upcomingMaintenanceSection: some View {
        Section(header: HStack {
            Text("Upcoming Maintenance")
            Spacer()
            if !viewModel.upcomingItems.isEmpty {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 7, height: 7)
                    Text("\(viewModel.upcomingItems.count) scheduled")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Color.secondary)
                        .textCase(.none)
                }
            }
        }) {
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
                        NavigationLink(value: destination) {
                            UpcomingMaintenanceCard(item: item)
                        }
                    } else {
                        UpcomingMaintenanceCard(item: item)
                    }
                }
            }
        }
    }



    // MARK: - KPI cell helper
    private func mKpiCell(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Upcoming Maintenance Card
struct UpcomingMaintenanceCard: View {
    let item: UpcomingDisplayItem

    var statusColor: Color {
        item.priorityColor ?? Color.blue
    }

    var body: some View {
        HStack(spacing: 16) {
            // Placeholder Image for Vehicle - themed with colors
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(statusColor.opacity(0.12))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "truck.box.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(statusColor)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.vehicleName)
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let priorityLabel = item.priorityLabel {
                        StatusBadge(text: priorityLabel.capitalized, color: statusColor)
                    } else {
                        StatusBadge(text: item.assignmentTag, color: Color.brown)
                    }
                }

                Text(item.taskDescription)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundStyle(statusColor)
                    Text("Est. \(item.estimatedDuration)")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }
}



// MARK: - Maintenance Stat Pill (matches Fleet Manager style locally)
struct MaintenanceStatPillLocal: View {
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
        .padding(.vertical, 16)
        .background(color.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(color.opacity(0.25), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct MaintenanceStatPillTextLocal: View {
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
        .padding(.vertical, 16)
        .background(color.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(color.opacity(0.25), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}