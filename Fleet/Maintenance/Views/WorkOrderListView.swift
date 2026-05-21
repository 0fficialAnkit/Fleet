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
            VStack {
                // Filter Picker
                Picker("Status Filter", selection: $selectedFilter) {
                    Text("All").tag(WorkOrderStatus?.none)
                    Text("Open").tag(WorkOrderStatus?.some(.open))
                    Text("In Progress").tag(WorkOrderStatus?.some(.inProgress))
                    Text("Completed").tag(WorkOrderStatus?.some(.completed))
                }
                .pickerStyle(.segmented)
                .padding()
                
                List(filteredOrders) { order in
                    NavigationLink(destination: WorkOrderDetailView(workOrder: order)) {
                        WorkOrderRow(workOrder: order)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Work Orders")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Action to create new work order
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

struct WorkOrderRow: View {
    let workOrder: WorkOrder
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Order: \(workOrder.id.uuidString.prefix(6))")
                    .font(.headline)
                Spacer()
                StatusBadge(status: workOrder.status ?? .open)
            }
            
            HStack {
                Label("Priority: \(workOrder.priority?.rawValue.capitalized ?? "Unknown")", systemImage: "flag.fill")
                    .foregroundColor(priorityColor(workOrder.priority))
                    .font(.subheadline)
                
                Spacer()
                
                Text(workOrder.createdAt ?? Date(), style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    func priorityColor(_ priority: WorkOrderPriority?) -> Color {
        switch priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        case .none: return .gray
        }
    }
}

struct StatusBadge: View {
    let status: WorkOrderStatus
    
    var body: some View {
        Text(status.rawValue.capitalized.replacingOccurrences(of: "_", with: " "))
            .font(.caption)
            .bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor.opacity(0.2))
            .foregroundColor(backgroundColor)
            .cornerRadius(8)
    }
    
    var backgroundColor: Color {
        switch status {
        case .open: return .blue
        case .inProgress: return .orange
        case .completed: return .green
        case .cancelled: return .red
        }
    }
}

#Preview {
    WorkOrderListView()
}
