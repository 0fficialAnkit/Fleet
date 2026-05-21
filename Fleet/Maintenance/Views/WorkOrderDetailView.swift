import SwiftUI

struct WorkOrderDetailView: View {
    let workOrder: WorkOrder
    @State private var notes: String = ""
    @State private var isCompleted: Bool = false
    @Environment(\.dismiss) private var dismiss

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
        case .high:     return ("High",     MBlue.accent)
        case .medium:   return ("Medium",   MBlue.inProgress)
        case .low:      return ("Low",      MBlue.textSecondary)
        default:        return ("—",        MBlue.textMuted)
        }
    }

    var body: some View {
        ZStack {
            AmbientBackground().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // ── Header Card ──
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("WO-\(workOrder.id.uuidString.prefix(6).uppercased())")
                                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                                    .foregroundColor(MBlue.textPrimary)
                                Text("Vehicle · \(workOrder.vehicleId.uuidString.prefix(8).uppercased())")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(MBlue.textSecondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 6) {
                                // Status
                                Text(statusConfig.label)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(statusConfig.color)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(statusConfig.color.opacity(0.15)))

                                // Priority
                                HStack(spacing: 4) {
                                    Image(systemName: "flag.fill")
                                        .font(.system(size: 10))
                                        .symbolRenderingMode(.hierarchical)
                                    Text(priorityConfig.label)
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(priorityConfig.color)
                            }
                        }
                    }
                    .padding(14)
                    .mCard()

                    // ── Details ──
                    WODetailSection(title: "Order Details", icon: "doc.text") {
                        WOInfoRow(label: "Order ID",   value: String(workOrder.id.uuidString.prefix(8).uppercased()))
                        WODivider()
                        WOInfoRow(label: "Vehicle",    value: String(workOrder.vehicleId.uuidString.prefix(8).uppercased()))
                        WODivider()
                        WOInfoRow(label: "Priority",   value: priorityConfig.label,   valueColor: priorityConfig.color)
                        WODivider()
                        WOInfoRow(label: "Status",     value: statusConfig.label,     valueColor: statusConfig.color)
                        if let date = workOrder.createdAt {
                            WODivider()
                            WOInfoRow(label: "Created", value: date.formatted(date: .abbreviated, time: .shortened))
                        }
                    }

                    // ── Parts ──
                    WODetailSection(title: "Parts Used", icon: "shippingbox") {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Brake Pads (Front)")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(MBlue.textPrimary)
                                Text("Part No. BP-2024-F")
                                    .font(.system(size: 11, weight: .regular, design: .rounded))
                                    .foregroundColor(MBlue.textSecondary)
                            }
                            Spacer()
                            Text("Qty: 2")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(MBlue.accentLight)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(MBlue.accentSoft)
                                )
                        }
                        .padding(.vertical, 4)

                        WODivider()

                        Button(action: { }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 15))
                                    .symbolRenderingMode(.hierarchical)
                                Text("Add Part")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(MBlue.accentLight)
                        }
                        .padding(.top, 4)
                    }

                    // ── Notes ──
                    WODetailSection(title: "Labor & Notes", icon: "note.text") {
                        TextField("Service details, observations…", text: $notes, axis: .vertical)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(MBlue.textPrimary)
                            .lineLimit(4...8)
                            .scrollContentBackground(.hidden)
                            .tint(MBlue.accentLight)
                    }

                    // ── Action Button ──
                    Button(action: { isCompleted.toggle() }) {
                        HStack {
                            Image(systemName: isCompleted ? "arrow.counterclockwise.circle.fill" : "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .symbolRenderingMode(.hierarchical)
                            Text(isCompleted ? "Mark as In Progress" : "Mark as Completed")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: isCompleted ? [MBlue.inProgress, MBlue.accentSky] : [MBlue.accent, MBlue.accentLight],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: (isCompleted ? MBlue.inProgress : MBlue.accent).opacity(0.3), radius: 8, y: 4)
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding(.top, 16)
                .padding(.horizontal)
            }
        }
        .navigationTitle("Order Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Detail Section Container
struct WODetailSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(MBlue.accentLight)
                    .symbolRenderingMode(.hierarchical)
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(MBlue.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            content
        }
        .padding(14)
        .mCard()
    }
}

// MARK: - Info Row
struct WOInfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = MBlue.textPrimary

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(MBlue.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(valueColor)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Divider
struct WODivider: View {
    var body: some View {
        Rectangle()
            .fill(MBlue.divider)
            .frame(height: 1)
    }
}


#Preview {
    NavigationStack {
        WorkOrderDetailView(workOrder: WorkOrder(
            id: UUID(), vehicleId: UUID(), createdBy: UUID(), assignedTo: UUID(),
            priority: .high, status: .open, createdAt: Date()
        ))
    }
}
