import SwiftUI

// MARK: - Internal display model (bridges WorkOrder ↔ ScheduledWorkOrder)

struct WorkOrderDisplayData {
    let id: UUID
    let vehicleDisplay: String
    let priority: WorkOrderPriority?
    var status: WorkOrderStatus?
    let createdAt: String
    let assignedBy: String
    let laborHours: String
    let laborCost: String
    var notes: String
    var partsUsed: [String]
}

// MARK: - Main View

struct WorkOrderDetailView: View {
    let data: WorkOrderDisplayData
    @State private var notes: String = ""
    @State private var currentStatus: WorkOrderStatus?
    @State private var showAddPartSheet = false
    @State private var newPartName = ""
    @State private var localParts: [String]

    // Init from DataModel WorkOrder (used by WorkOrderListView)
    init(workOrder: WorkOrder) {
        let d = WorkOrderDisplayData(
            id: workOrder.id,
            vehicleDisplay: "VH-\(workOrder.vehicleId.uuidString.prefix(8).uppercased())",
            priority: workOrder.priority,
            status: workOrder.status,
            createdAt: workOrder.createdAt.map { $0.formatted(date: .abbreviated, time: .shortened) } ?? "N/A",
            assignedBy: "N/A",
            laborHours: "N/A",
            laborCost: "N/A",
            notes: "",
            partsUsed: []
        )
        self.data = d
        _currentStatus = State(initialValue: workOrder.status)
        _notes = State(initialValue: "")
        _localParts = State(initialValue: [])
    }

    // Init from ScheduledWorkOrder (used by MaintenanceSchedulerView cards)
    init(scheduledWorkOrder wo: ScheduledWorkOrder) {
        let d = WorkOrderDisplayData(
            id: wo.id,
            vehicleDisplay: "\(wo.vehicleName) · \(wo.vehicleNumber)",
            priority: wo.priority,
            status: wo.status,
            createdAt: wo.createdAt.formatted(date: .abbreviated, time: .shortened),
            assignedBy: wo.assignedBy,
            laborHours: wo.laborHours,
            laborCost: wo.laborCost,
            notes: wo.notes,
            partsUsed: wo.partsUsed
        )
        self.data = d
        _currentStatus = State(initialValue: wo.status)
        _notes = State(initialValue: wo.notes)
        _localParts = State(initialValue: wo.partsUsed)
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {

                    // MARK: - Status Banner
                    HStack(spacing: 8) {
                        Image(systemName: statusIcon(currentStatus))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(statusColor(currentStatus))
                        Text(statusLabel(currentStatus))
                            .font(.system(size: , weight: .semibold, design: .rounded))
                            .foregroundStyle(statusColor(currentStatus))
                        Spacer()
                        StatusBadge(
                            text: priorityLabel(data.priority),
                            color: priorityColor(data.priority),
                            icon: priorityIcon(data.priority)
                        )
                    }
                    .padding(16)
                    .background(statusColor(currentStatus).opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(statusColor(currentStatus).opacity(0.25), lineWidth: 1)
                    )

                    // MARK: - Details Section
                    GlassSection(title: "Order Details") {
                        InfoRow(icon: "number",       label: "Order ID",    value: "WO-\(data.id.uuidString.prefix(8).uppercased())")
                        divider
                        InfoRow(icon: "car.fill",     label: "Vehicle",     value: data.vehicleDisplay)
                        divider
                        InfoRow(icon: "flag.fill",    label: "Priority",    value: priorityLabel(data.priority), valueColor: priorityColor(data.priority))
                        divider
                        InfoRow(icon: "person.fill",  label: "Assigned By", value: data.assignedBy)
                        divider
                        InfoRow(icon: "calendar",     label: "Created",     value: data.createdAt)
                    }

                    // MARK: - Labor & Notes
                    GlassSection(title: "Labor & Financials") {
                        HStack(spacing: 16) {
                            LaborStat(label: "Est. Hours", value: data.laborHours, icon: "clock.fill",           color: Color.blue)
                            LaborStat(label: "Labor Cost",  value: data.laborCost,  icon: "indianrupeesign.circle.fill", color: Color.green)
                        }
                    }

                    // MARK: - Parts Used
                    GlassSection(title: "Parts Used") {
                        Button(action: { showAddPartSheet = true }) {
                            ActionRow(
                                icon: "plus.circle.fill",
                                title: "Add Part from Inventory",
                                iconColor: Color.orange
                            )
                        }
                        .buttonStyle(.plain)

                        if !localParts.isEmpty {
                            Divider().background(Color(UIColor.separator))
                            ForEach(Array(localParts.enumerated()), id: \.offset) { idx, part in
                                HStack(spacing: 16) {
                                    Image(systemName: "gearshape.2.fill")
                                        .foregroundStyle(Color.orange)
                                        .frame(width: 20)
                                    Text(part)
                                        .font(.system(size: , weight: .regular, design: .rounded))
                                        .foregroundStyle(Color.primary)
                                    Spacer()
                                }
                                if idx < localParts.count - 1 {
                                    Divider().background(Color(UIColor.separator))
                                }
                            }
                        }
                    }

                    // MARK: - Service Notes
                    GlassSection(title: "Service Notes") {
                        TextField("Add service details, notes or observations...", text: $notes, axis: .vertical)
                            .lineLimit(4...8)
                            .font(.system(size: , weight: .regular, design: .rounded))
                            .foregroundStyle(Color.primary)
                    }

                    // MARK: - Action Buttons
                    VStack(spacing: 16) {
                        if currentStatus == .open {
                            ActionButton(title: "Start Work Order", icon: "play.circle.fill", color: Color.orange) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { currentStatus = .inProgress }
                            }
                        }
                        if currentStatus == .inProgress {
                            ActionButton(title: "Mark as Completed", icon: "checkmark.circle.fill", color: Color.green) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { currentStatus = .completed }
                            }
                        }
                        if currentStatus == .completed {
                            ActionButton(title: "Reopen Order", icon: "arrow.counterclockwise.circle.fill", color: Color.yellow) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { currentStatus = .inProgress }
                            }
                        }
                        if currentStatus != .cancelled {
                            ActionButton(title: "Cancel Order", icon: "xmark.circle", color: Color.red) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { currentStatus = .cancelled }
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
                .padding(16)
            }
        }
        .navigationTitle("Work Order")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddPartSheet) {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("Add Spare Part")
                        .font(.system(size: , weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.primary)
                        .padding(.top, 24)

                    TextField("Part Name (e.g. Air Filter)", text: $newPartName)
                        .font(.system(size: , weight: .regular, design: .rounded))
                        .padding(12)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)

                    Button {
                        guard !newPartName.isEmpty else { return }
                        localParts.append(newPartName)
                        newPartName = ""
                        showAddPartSheet = false
                    } label: {
                        Text("Add to Consumed Parts")
                            .font(.system(size: , weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                    }

                    Spacer()
                }
            }
            .presentationDetents([.fraction(0.35)])
        }
    }

    private var divider: some View { Divider().background(Color(UIColor.separator)) }

    // MARK: - Helpers
    func statusIcon(_ s: WorkOrderStatus?) -> String {
        switch s {
        case .open:       return "tray.circle"
        case .inProgress: return "wrench.adjustable"
        case .completed:  return "checkmark.circle.fill"
        case .cancelled:  return "xmark.circle.fill"
        case .none:       return "tray.circle"
        }
    }
    func statusLabel(_ s: WorkOrderStatus?) -> String {
        switch s {
        case .open:       return "Open"
        case .inProgress: return "In Progress"
        case .completed:  return "Completed"
        case .cancelled:  return "Cancelled"
        case .none:       return "Unknown"
        }
    }
    func statusColor(_ s: WorkOrderStatus?) -> Color {
        switch s {
        case .open:       return Color.blue
        case .inProgress: return Color.yellow
        case .completed:  return Color.green
        case .cancelled:  return Color.red
        case .none:       return Color.secondary
        }
    }
    func priorityLabel(_ p: WorkOrderPriority?) -> String {
        switch p {
        case .low:      return "Low"
        case .medium:   return "Medium"
        case .high:     return "High"
        case .critical: return "Critical"
        case .none:     return "N/A"
        }
    }
    func priorityIcon(_ p: WorkOrderPriority?) -> String {
        switch p {
        case .low:      return "arrow.down.circle"
        case .medium:   return "minus.circle"
        case .high:     return "arrow.up.circle"
        case .critical: return "exclamationmark.2"
        case .none:     return "minus.circle"
        }
    }
    func priorityColor(_ p: WorkOrderPriority?) -> Color {
        switch p {
        case .critical: return Color.red
        case .high:     return Color.yellow
        case .medium:   return Color.blue
        case .low:      return Color.green
        case .none:     return Color.secondary
        }
    }
}

// MARK: - GlassSection
private struct GlassSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: title)
            VStack(spacing: 16) {
                content()
            }
            .padding(16)
            .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
        }
    }
}

// MARK: - Part Row
private struct PartRow: View {
    let icon: String
    let name: String
    let qty: Int
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon).foregroundStyle(color).frame(width: 22)
            Text(name).font(.system(size: , weight: .regular, design: .rounded)).foregroundStyle(Color.primary)
            Spacer()
            Text("×\(qty)").font(.system(size: , weight: .medium, design: .rounded)).foregroundStyle(Color.secondary)
        }
    }
}

// MARK: - Labor Stat
private struct LaborStat: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.system(size: , weight: .semibold, design: .rounded)).foregroundStyle(Color.primary)
                Text(label).font(.system(size: , weight: .regular, design: .rounded)).foregroundStyle(Color(UIColor.tertiaryLabel))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Action Button
private struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: , weight: .semibold, design: .rounded))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(16)
            .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.15), radius: 8, y: 4)
        }
    }
}

#Preview {
    NavigationStack {
        WorkOrderDetailView(workOrder: WorkOrder(
            id: UUID(), vehicleId: UUID(), createdBy: UUID(), assignedTo: UUID(),
            priority: .high, status: .inProgress, createdAt: Date()
        ))
    }
}
