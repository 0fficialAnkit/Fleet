import SwiftUI

struct WorkOrderListView: View {
    @State private var selectedFilter: WorkOrderStatus? = nil

    let workOrders = [
        WorkOrder(id: UUID(), vehicleId: UUID(), createdBy: UUID(), assignedTo: UUID(), priority: .high,     status: .open,       createdAt: Date().addingTimeInterval(-86400)),
        WorkOrder(id: UUID(), vehicleId: UUID(), createdBy: UUID(), assignedTo: UUID(), priority: .medium,   status: .inProgress, createdAt: Date().addingTimeInterval(-172800)),
        WorkOrder(id: UUID(), vehicleId: UUID(), createdBy: UUID(), assignedTo: UUID(), priority: .critical, status: .completed,  createdAt: Date().addingTimeInterval(-259200)),
        WorkOrder(id: UUID(), vehicleId: UUID(), createdBy: UUID(), assignedTo: UUID(), priority: .low,      status: .open,       createdAt: Date().addingTimeInterval(-43200)),
        WorkOrder(id: UUID(), vehicleId: UUID(), createdBy: UUID(), assignedTo: UUID(), priority: .high,     status: .cancelled,  createdAt: Date().addingTimeInterval(-320000))
    ]

    var filteredOrders: [WorkOrder] {
        guard let filter = selectedFilter else { return workOrders }
        return workOrders.filter { $0.status == filter }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground().ignoresSafeArea()

                VStack(spacing: 0) {
                    // ── Filter Chips ──
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            WOFilterChip(label: "All",         tag: nil,           selected: selectedFilter == nil) { selectedFilter = nil }
                            WOFilterChip(label: "Open",        tag: .open,         selected: selectedFilter == .open)       { selectedFilter = .open }
                            WOFilterChip(label: "In Progress", tag: .inProgress,   selected: selectedFilter == .inProgress) { selectedFilter = .inProgress }
                            WOFilterChip(label: "Completed",   tag: .completed,    selected: selectedFilter == .completed)  { selectedFilter = .completed }
                            WOFilterChip(label: "Cancelled",   tag: .cancelled,    selected: selectedFilter == .cancelled)  { selectedFilter = .cancelled }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }

                    Divider()

                    // ── List ──
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredOrders) { order in
                                NavigationLink(destination: WorkOrderDetailView(workOrder: order)) {
                                    WOCard(workOrder: order)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Work Orders")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(MBlue.accentLight)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
        }
    }
}

// MARK: - Filter Chip
struct WOFilterChip: View {
    let label: String
    let tag: WorkOrderStatus?
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(selected ? .white : MBlue.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(selected ? Capsule().fill(MBlue.accent) : nil)
                .glassEffect(.regular, in: Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(
                            selected ? MBlue.accent : MBlue.accentBorder.opacity(0.4),
                            lineWidth: 0.8
                        )
                )
        }
    }
}

// MARK: - Work Order Card
struct WOCard: View {
    let workOrder: WorkOrder

    private var statusConfig: (label: String, color: Color) {
        switch workOrder.status {
        case .open:       return ("Open",        MBlue.accent)
        case .inProgress: return ("In Progress", MBlue.inProgress)
        case .completed:  return ("Completed",   MBlue.completed)
        case .cancelled:  return ("Cancelled",   MBlue.textMuted)
        default:          return ("Unknown",     MBlue.textMuted)
        }
    }

    private var priorityConfig: (label: String, color: Color) {
        switch workOrder.priority {
        case .critical: return ("Critical", MBlue.critical)
        case .high:     return ("High",     MBlue.accentLight)
        case .medium:   return ("Medium",   MBlue.inProgress)
        case .low:      return ("Low",      MBlue.textSecondary)
        default:        return ("—",        MBlue.textMuted)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row
            HStack {
                Label {
                    Text("WO-\(workOrder.id.uuidString.prefix(6).uppercased())")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(MBlue.accentLight)
                } icon: {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(MBlue.accent)
                        .symbolRenderingMode(.hierarchical)
                }

                Spacer()

                // Status pill
                Text(statusConfig.label)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(statusConfig.color)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(statusConfig.color.opacity(0.13))
                    )
            }

            Rectangle().fill(MBlue.divider).frame(height: 1)

            // Bottom row
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(priorityConfig.color)
                        .symbolRenderingMode(.hierarchical)
                    Text(priorityConfig.label)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(priorityConfig.color)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(priorityConfig.color.opacity(0.12))
                )

                Spacer()

                if let date = workOrder.createdAt {
                    Text(date, style: .date)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(MBlue.textSecondary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(MBlue.accentBright)
                    .padding(.leading, 4)
            }
        }
        .padding(12)
        .mCard()
    }
}

// MARK: - Status Badge (kept for legacy compatibility)
struct StatusBadge: View {
    let status: WorkOrderStatus

    private var config: (label: String, color: Color) {
        switch status {
        case .open:       return ("Open",        MBlue.accent)
        case .inProgress: return ("In Progress", MBlue.inProgress)
        case .completed:  return ("Completed",   MBlue.completed)
        case .cancelled:  return ("Cancelled",   MBlue.textMuted)
        }
    }

    var body: some View {
        Text(config.label)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(config.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(config.color.opacity(0.15)))
    }
}

#Preview {
    WorkOrderListView()
}
