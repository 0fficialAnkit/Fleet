import SwiftUI

struct WorkOrderDetailView: View {
    let workOrder: WorkOrder
    @State private var notes: String = ""
    @State private var isCompleted: Bool = false
    
    var body: some View {
        ZStack {
            themeModel.backgroundPrimary.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: themeModel.spacingMD) {
                    // Details Section
                    VStack(alignment: .leading, spacing: themeModel.spacingSM) {
                        SectionHeader(title: "Details")
                        
                        
                            VStack(spacing: themeModel.spacingMD) {
                                InfoRow(icon: "number", label: "Order ID", value: String(workOrder.id.uuidString.prefix(8)))
                                InfoRow(icon: "car", label: "Vehicle ID", value: String(workOrder.vehicleId.uuidString.prefix(8)))
                                InfoRow(icon: "flag.fill", label: "Priority", value: workOrder.priority?.rawValue.capitalized ?? "N/A", valueColor: priorityColor(workOrder.priority))
                                InfoRow(icon: "tag.fill", label: "Status", value: workOrder.status?.rawValue.capitalized ?? "N/A", valueColor: statusColor(workOrder.status))
                            }
                            .padding(themeModel.spacingMD)
                            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                            )
                            .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
                    }
                    
                    // Parts Used Section
                    VStack(alignment: .leading, spacing: themeModel.spacingSM) {
                        SectionHeader(title: "Parts Used")
                        
                        
                            VStack(spacing: themeModel.spacingMD) {
                                Button(action: {
                                    // Action to add parts from inventory
                                }) {
                                    ActionRow(icon: "plus.circle", title: "Add Part", iconColor: themeModel.maintenancePrimary)
                                }
                                
                                Divider()
                                    .background(themeModel.textTertiary.opacity(0.3))
                                
                                // Mock used part
                                HStack {
                                    Image(systemName: "gearshape.2")
                                        .foregroundColor(themeModel.textTertiary)
                                    Text("Brake Pads (Front)")
                                        .font(themeModel.body())
                                        .foregroundStyle(themeModel.textPrimary)
                                    Spacer()
                                    Text("Qty: 2")
                                        .font(themeModel.bodyMedium())
                                        .foregroundColor(themeModel.textSecondary)
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
                    
                    // Labor & Notes Section
                    VStack(alignment: .leading, spacing: themeModel.spacingSM) {
                        SectionHeader(title: "Labor & Notes")
                        
                        
VStack(spacing: 0) {
                            TextField("Service Details or Notes", text: $notes, axis: .vertical)
                                .lineLimit(4...8)
                                .font(themeModel.body())
                                .foregroundStyle(themeModel.textPrimary)
                        
                        }
                        .padding(themeModel.spacingMD)
                        .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                        )
                        .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
                    }
                    
                    // Action Button
                    Button(action: {
                        isCompleted.toggle()
                    }) {
                        
                            HStack(spacing: themeModel.spacingSM) {
                                Image(systemName: isCompleted ? "arrow.counterclockwise.circle" : "checkmark.circle")
                                Text(isCompleted ? "Mark as In Progress" : "Mark as Completed")
                            }
                            .font(themeModel.headline())
                            .foregroundColor(isCompleted ? themeModel.warning : themeModel.success)
                            .frame(maxWidth: .infinity)
                            .padding(themeModel.spacingMD)
                            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                            )
                            .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
                    }
                    .padding(.top, themeModel.spacingSM)
                }
                .padding(themeModel.spacingMD)
            }
        }
        .navigationTitle("Order Details")
        .navigationBarTitleDisplayMode(.inline)
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
    WorkOrderDetailView(workOrder: WorkOrder(id: UUID(), vehicleId: UUID(), createdBy: UUID(), assignedTo: UUID(), priority: .high, status: .open, createdAt: Date()))
}
