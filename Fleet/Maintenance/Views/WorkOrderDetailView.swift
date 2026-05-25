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
            themeModel.backgroundPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: themeModel.spacingLG) {

                    // MARK: - Status Banner
                    HStack(spacing: themeModel.spacingSM) {
                        Image(systemName: statusIcon(currentStatus))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(statusColor(currentStatus))
                        Text(statusLabel(currentStatus))
                            .font(themeModel.headline())
                            .foregroundStyle(statusColor(currentStatus))
                        Spacer()
                        StatusBadge(
                            text: priorityLabel(data.priority),
                            color: priorityColor(data.priority),
                            icon: priorityIcon(data.priority)
                        )
                    }
                    .padding(themeModel.spacingMD)
                    .background(statusColor(currentStatus).opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
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
                        HStack(spacing: themeModel.spacingMD) {
                            LaborStat(label: "Est. Hours", value: data.laborHours, icon: "clock.fill",           color: themeModel.info)
                            LaborStat(label: "Labor Cost",  value: data.laborCost,  icon: "indianrupeesign.circle.fill", color: themeModel.success)
                        }
                    }

                    // MARK: - Parts Used
                    GlassSection(title: "Parts Used") {
                        Button(action: { showAddPartSheet = true }) {
                            ActionRow(
                                icon: "plus.circle.fill",
                                title: "Add Part from Inventory",
                                iconColor: themeModel.maintenancePrimary
                            )
                        }
                        .buttonStyle(.plain)

                        if !localParts.isEmpty {
                            Divider().background(themeModel.divider)
                            ForEach(Array(localParts.enumerated()), id: \.offset) { idx, part in
                                HStack(spacing: themeModel.spacingMD) {
                                    Image(systemName: "gearshape.2.fill")
                                        .foregroundStyle(themeModel.maintenancePrimary)
                                        .frame(width: 20)
                                    Text(part)
                                        .font(themeModel.body())
                                        .foregroundStyle(themeModel.textPrimary)
                                    Spacer()
                                }
                                if idx < localParts.count - 1 {
                                    Divider().background(themeModel.divider)
                                }
                            }
                        }
                    }

                    // MARK: - Service Notes
                    GlassSection(title: "Service Notes") {
                        TextField("Add service details, notes or observations...", text: $notes, axis: .vertical)
                            .lineLimit(4...8)
                            .font(themeModel.body())
                            .foregroundStyle(themeModel.textPrimary)
                    }

                    // MARK: - Action Buttons
                    VStack(spacing: themeModel.spacingMD) {
                        if currentStatus == .open {
                            ActionButton(title: "Start Work Order", icon: "play.circle.fill", color: themeModel.maintenancePrimary) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { currentStatus = .inProgress }
                            }
                        }
                        if currentStatus == .inProgress {
                            ActionButton(title: "Mark as Completed", icon: "checkmark.circle.fill", color: themeModel.success) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { currentStatus = .completed }
                            }
                        }
                        if currentStatus == .completed {
                            ActionButton(title: "Reopen Order", icon: "arrow.counterclockwise.circle.fill", color: themeModel.warning) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { currentStatus = .inProgress }
                            }
                        }
                        if currentStatus != .cancelled {
                            ActionButton(title: "Cancel Order", icon: "xmark.circle", color: themeModel.danger) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { currentStatus = .cancelled }
                            }
                        }
                    }
                    .padding(.bottom, themeModel.spacingLG)
                }
                .padding(themeModel.spacingMD)
            }
        }
        .navigationTitle("Work Order")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddPartSheet) {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("Add Spare Part")
                        .font(themeModel.headline())
                        .foregroundStyle(themeModel.textPrimary)
                        .padding(.top, 24)

                    TextField("Part Name (e.g. Air Filter)", text: $newPartName)
                        .font(themeModel.body())
                        .padding(12)
                        .background(themeModel.surfaceTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)

                    Button {
                        guard !newPartName.isEmpty else { return }
                        localParts.append(newPartName)
                        newPartName = ""
                        showAddPartSheet = false
                    } label: {
                        Text("Add to Consumed Parts")
                            .font(themeModel.headline())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(themeModel.maintenancePrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                    }

                    Spacer()
                }
            }
            .presentationDetents([.fraction(0.35)])
        }
    }

    private var divider: some View { Divider().background(themeModel.divider) }

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
        case .open:       return themeModel.info
        case .inProgress: return themeModel.warning
        case .completed:  return themeModel.success
        case .cancelled:  return themeModel.danger
        case .none:       return themeModel.textSecondary
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
        case .critical: return themeModel.danger
        case .high:     return themeModel.warning
        case .medium:   return themeModel.info
        case .low:      return themeModel.success
        case .none:     return themeModel.textSecondary
        }
    }
}

// MARK: - GlassSection
private struct GlassSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
            SectionHeader(title: title)
            VStack(spacing: themeModel.spacingMD) {
                content()
            }
            .padding(themeModel.spacingMD)
            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            )
            .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
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
        HStack(spacing: themeModel.spacingMD) {
            Image(systemName: icon).foregroundStyle(color).frame(width: 22)
            Text(name).font(themeModel.body()).foregroundStyle(themeModel.textPrimary)
            Spacer()
            Text("×\(qty)").font(themeModel.bodyMedium()).foregroundStyle(themeModel.textSecondary)
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
        HStack(spacing: themeModel.spacingSM) {
            Image(systemName: icon).foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(themeModel.headline()).foregroundStyle(themeModel.textPrimary)
                Text(label).font(themeModel.caption()).foregroundStyle(themeModel.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(themeModel.spacingMD)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous))
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
            HStack(spacing: themeModel.spacingSM) {
                Image(systemName: icon)
                Text(title)
            }
            .font(themeModel.headline())
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(themeModel.spacingMD)
            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
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
