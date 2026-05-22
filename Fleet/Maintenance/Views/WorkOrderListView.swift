import SwiftUI

struct WorkOrderListView: View {
    @State private var selectedFilter: WorkOrderStatus? = nil
    
    // Dummy Data based on DataModel
    let workOrders = [
        WorkOrder(id: UUID(), vehicleId: UUID(), createdBy: UUID(), assignedTo: UUID(), priority: .high, status: .open, createdAt: Date().addingTimeInterval(-86400)),
        WorkOrder(id: UUID(), vehicleId: UUID(), createdBy: UUID(), assignedTo: UUID(), priority: .medium, status: .inProgress, createdAt: Date().addingTimeInterval(-172800)),
        WorkOrder(id: UUID(), vehicleId: UUID(), createdBy: UUID(), assignedTo: UUID(), priority: .critical, status: .completed, createdAt: Date().addingTimeInterval(-259200))
    ]
    
    var filteredOrders: [WorkOrder] {
        if let filter = selectedFilter {
            return workOrders.filter { $0.status == filter }
        }
        return workOrders
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: themeModel.spacingMD) {
                        // Filter Picker
                        Picker("Status Filter", selection: $selectedFilter) {
                            Text("All").tag(WorkOrderStatus?.none)
                            Text("Open").tag(WorkOrderStatus?.some(.open))
                            Text("In Progress").tag(WorkOrderStatus?.some(.inProgress))
                            Text("Completed").tag(WorkOrderStatus?.some(.completed))
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, themeModel.spacingMD)
                        
                        LazyVStack(spacing: themeModel.spacingMD) {
                            ForEach(filteredOrders) { order in
                                NavigationLink(destination: WorkOrderDetailView(workOrder: order)) {
                                    WorkOrderRow(workOrder: order)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, themeModel.spacingMD)
                    }
                    .padding(.vertical, themeModel.spacingMD)
                }
            }
            .navigationTitle("Work Orders")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Action to create new work order
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(themeModel.maintenancePrimary)
                    }
                }
            }
        }
    }
}

struct WorkOrderRow: View {
    let workOrder: WorkOrder
    
    var body: some View {
        
            VStack(alignment: .leading, spacing: themeModel.spacingMD) {
                HStack {
                    Text("Order: \(workOrder.id.uuidString.prefix(6))")
                        .font(themeModel.headline())
                        .foregroundStyle(themeModel.textPrimary)
                    Spacer()
                    StatusBadge(text: workOrder.status?.rawValue.capitalized ?? "Open", color: statusColor(workOrder.status))
                }
                
                HStack {
                    Label {
                        Text("Priority: \(workOrder.priority?.rawValue.capitalized ?? "Unknown")")
                            .font(themeModel.bodyMedium())
                            .foregroundStyle(themeModel.textSecondary)
                    } icon: {
                        Image(systemName: priorityIcon(workOrder.priority))
                            .foregroundColor(priorityColor(workOrder.priority))
                    }
                    
                    Spacer()
                    
                    Text(workOrder.createdAt ?? Date(), style: .date)
                        .font(themeModel.caption())
                        .foregroundStyle(themeModel.textTertiary)
                }
            }
            .padding(themeModel.spacingMD)
            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
    }
    
    func statusColor(_ status: WorkOrderStatus?) -> Color {
        switch status {
        case .open: return themeModel.info
        case .inProgress: return themeModel.warning
        case .completed: return themeModel.success
        case .cancelled: return themeModel.danger
        case .none: return themeModel.textSecondary
        }
    }
    
    func priorityIcon(_ priority: WorkOrderPriority?) -> String {
        switch priority {
        case .low: return "arrow.down"
        case .medium: return "minus"
        case .high: return "arrow.up"
        case .critical: return "exclamationmark.2"
        case .none: return "minus"
        }
    }

    func priorityColor(_ priority: WorkOrderPriority?) -> Color {
        switch priority {
        case .critical: return themeModel.danger
        case .high: return themeModel.warning
        case .medium: return themeModel.info
        case .low: return themeModel.success
        case .none: return themeModel.textSecondary
        }
    }
}

#Preview {
    WorkOrderListView()
}
