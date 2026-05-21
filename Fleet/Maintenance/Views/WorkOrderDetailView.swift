import SwiftUI

struct WorkOrderDetailView: View {
    let workOrder: WorkOrder
    @State private var notes: String = ""
    @State private var isCompleted: Bool = false
    
    var body: some View {
        Form {
            Section("Details") {
                LabeledContent("Order ID", value: String(workOrder.id.uuidString.prefix(8)))
                LabeledContent("Vehicle ID", value: String(workOrder.vehicleId.uuidString.prefix(8)))
                LabeledContent("Priority", value: workOrder.priority?.rawValue.capitalized ?? "N/A")
                LabeledContent("Status", value: workOrder.status?.rawValue.capitalized ?? "N/A")
            }
            
            Section("Parts Used") {
                Button(action: {
                    // Action to add parts from inventory
                }) {
                    Label("Add Part", systemImage: "plus.circle")
                }
                
                // Mock used part
                HStack {
                    Text("Brake Pads (Front)")
                    Spacer()
                    Text("Qty: 2")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Labor & Notes") {
                TextField("Service Details or Notes", text: $notes, axis: .vertical)
                    .lineLimit(4...8)
            }
            
            Section {
                Button(action: {
                    isCompleted.toggle()
                }) {
                    Text(isCompleted ? "Mark as In Progress" : "Mark as Completed")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(isCompleted ? .orange : .green)
                }
            }
        }
        .navigationTitle("Order Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    WorkOrderDetailView(workOrder: WorkOrder(id: UUID(), vehicleId: UUID(), createdBy: UUID(), assignedTo: UUID(), priority: .high, status: .open, createdAt: Date()))
}
