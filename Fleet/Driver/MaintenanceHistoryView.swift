import SwiftUI

// MARK: - Main View

struct MaintenanceHistoryView: View {

    let vehicle: Vehicle

    // MARK: - State
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: HistoryFilter = .all
    @State private var appeared = false

    enum HistoryFilter: String, CaseIterable {
        case all       = "All"
        case tasks     = "Tasks"
        case workOrders = "Work Orders"
        case critical  = "Critical"
    }

    // MARK: - Rich Mock Data

    struct MaintenanceRecord: Identifiable {
        let id = UUID()
        let type: RecordType
        let title: String
        let issueResolved: String
        let technicianName: String
        let date: Date
        let cost: Double
        let parts: [PartUsed]
        let priority: WorkOrderPriority
        let hoursSpent: Double
        let odometer: String
        let notes: String?

        enum RecordType { case task, workOrder }
    }

    struct PartUsed: Identifiable {
        let id = UUID()
        let name: String
        let quantity: Int
        let unitCost: Double
    }

    let records: [MaintenanceRecord] = [
        MaintenanceRecord(
            type: .workOrder,
            title: "Brake System Overhaul",
            issueResolved: "Front brake pads worn beyond safe limit; caliper leaking",
            technicianName: "Ravi Sharma",
            date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            cost: 8750,
            parts: [
                PartUsed(name: "Brake Pads (Front)", quantity: 2, unitCost: 1200),
                PartUsed(name: "Brake Caliper Seal Kit", quantity: 1, unitCost: 850),
                PartUsed(name: "Brake Fluid DOT4", quantity: 1, unitCost: 350),
            ],
            priority: .critical,
            hoursSpent: 3.5,
            odometer: "47,812 km",
            notes: "Vehicle grounded until repair completed. Road-test passed post-repair."
        ),
        MaintenanceRecord(
            type: .task,
            title: "Engine Oil Change",
            issueResolved: "Scheduled oil change at 47,500 km interval",
            technicianName: "Deepak Verma",
            date: Calendar.current.date(byAdding: .day, value: -9, to: Date())!,
            cost: 2600,
            parts: [
                PartUsed(name: "Engine Oil 5W-30 (5L)", quantity: 2, unitCost: 850),
                PartUsed(name: "Oil Filter", quantity: 1, unitCost: 320),
            ],
            priority: .medium,
            hoursSpent: 1.0,
            odometer: "47,500 km",
            notes: nil
        ),
        MaintenanceRecord(
            type: .task,
            title: "Tire Rotation & Balancing",
            issueResolved: "Uneven tread wear detected on rear tires",
            technicianName: "Suresh Nair",
            date: Calendar.current.date(byAdding: .day, value: -18, to: Date())!,
            cost: 1200,
            parts: [
                PartUsed(name: "Wheel Weights", quantity: 4, unitCost: 80),
            ],
            priority: .low,
            hoursSpent: 1.5,
            odometer: "47,100 km",
            notes: "Rear-to-front rotation completed. Pressure set to 35 PSI."
        ),
        MaintenanceRecord(
            type: .workOrder,
            title: "Air Filter & Cabin Filter Replacement",
            issueResolved: "Clogged engine air filter reducing fuel efficiency",
            technicianName: "Ravi Sharma",
            date: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
            cost: 980,
            parts: [
                PartUsed(name: "Engine Air Filter", quantity: 1, unitCost: 550),
                PartUsed(name: "Cabin Air Filter", quantity: 1, unitCost: 280),
            ],
            priority: .medium,
            hoursSpent: 0.5,
            odometer: "46,800 km",
            notes: nil
        ),
        MaintenanceRecord(
            type: .workOrder,
            title: "Transmission Fluid Service",
            issueResolved: "Delayed gear shifts; fluid degraded at 45k km mark",
            technicianName: "Ajay Pillai",
            date: Calendar.current.date(byAdding: .month, value: -2, to: Date())!,
            cost: 3400,
            parts: [
                PartUsed(name: "ATF Fluid (4L)", quantity: 1, unitCost: 1800),
                PartUsed(name: "Transmission Filter", quantity: 1, unitCost: 950),
                PartUsed(name: "Drain Plug Gasket", quantity: 1, unitCost: 120),
            ],
            priority: .high,
            hoursSpent: 2.0,
            odometer: "45,200 km",
            notes: "Shift quality improved post-service. Follow-up check in 5,000 km."
        ),
        MaintenanceRecord(
            type: .task,
            title: "Full Vehicle Inspection",
            issueResolved: "Annual DOT compliance inspection",
            technicianName: "Deepak Verma",
            date: Calendar.current.date(byAdding: .month, value: -3, to: Date())!,
            cost: 1500,
            parts: [],
            priority: .medium,
            hoursSpent: 2.5,
            odometer: "44,100 km",
            notes: "All systems passed. Minor rust on undercarriage noted for monitoring."
        ),
    ]

    var filteredRecords: [MaintenanceRecord] {
        switch selectedFilter {
        case .all:        return records
        case .tasks:      return records.filter { $0.type == .task }
        case .workOrders: return records.filter { $0.type == .workOrder }
        case .critical:   return records.filter { $0.priority == .critical || $0.priority == .high }
        }
    }

    var totalCost: Double { records.reduce(0) { $0 + $1.cost } }
    var totalServices: Int { records.count }
    var totalHours: Double { records.reduce(0) { $0 + $1.hoursSpent } }

    // MARK: - Body

    var body: some View {
        ZStack {
            FleetTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar
                filterBar
                    .padding(.top, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        summaryCards
                        timeline
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }

    // MARK: - Nav Bar

    var navBar: some View {
        HStack(spacing: 14) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(FleetTheme.card)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(FleetTheme.cardBorder, lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Maintenance History")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                Text("\(vehicle.make ?? "") \(vehicle.model ?? "") · \(vehicle.licensePlate ?? "")")
                    .font(.system(size: 13))
                    .foregroundStyle(.gray)
            }

            Spacer()

            Button {} label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(FleetTheme.card)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(FleetTheme.cardBorder, lineWidth: 1))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: - Filter Bar

    var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(HistoryFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedFilter = filter
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if filter == .critical {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 11))
                            }
                            Text(filter.rawValue)
                                .font(.system(size: 14, weight: selectedFilter == filter ? .semibold : .regular))
                        }
                        .foregroundStyle(selectedFilter == filter ? .black : .gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(selectedFilter == filter ? FleetTheme.accent : FleetTheme.card)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(
                                selectedFilter == filter ? Color.clear : FleetTheme.cardBorder,
                                lineWidth: 1
                            )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Summary Cards

    var summaryCards: some View {
        HStack(spacing: 14) {
            summaryStat(
                icon: "wrench.and.screwdriver.fill",
                value: "\(totalServices)",
                label: "Services",
                color: FleetTheme.accentBlue
            )
            summaryStat(
                icon: "indianrupeesign.circle.fill",
                value: String(format: "₹%.1fk", totalCost / 1000),
                label: "Total Cost",
                color: FleetTheme.accentOrange
            )
            summaryStat(
                icon: "clock.fill",
                value: String(format: "%.0fh", totalHours),
                label: "Shop Time",
                color: FleetTheme.accentPurple
            )
        }
    }

    func summaryStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(color.opacity(0.12)).frame(width: 42, height: 42)
                Image(systemName: icon).font(.system(size: 17)).foregroundStyle(color)
            }
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(FleetTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(FleetTheme.cardBorder, lineWidth: 1))
    }

    // MARK: - Timeline

    var timeline: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Service Timeline")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(filteredRecords.count) records")
                    .font(.system(size: 13))
                    .foregroundStyle(.gray)
            }
            .padding(.bottom, 16)

            if filteredRecords.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(filteredRecords.enumerated()), id: \.element.id) { index, record in
                        HStack(alignment: .top, spacing: 14) {
                            // Timeline spine
                            VStack(spacing: 0) {
                                timelineDot(record: record)
                                if index < filteredRecords.count - 1 {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.08))
                                        .frame(width: 2)
                                        .frame(maxHeight: .infinity)
                                }
                            }
                            .frame(width: 28)

                            MaintenanceRecordCard(record: record)
                                .padding(.bottom, index < filteredRecords.count - 1 ? 16 : 0)
                        }
                    }
                }
            }
        }
    }

    func timelineDot(record: MaintenanceRecord) -> some View {
        let color = priorityColor(record.priority)
        return ZStack {
            Circle().fill(color.opacity(0.2)).frame(width: 28, height: 28)
            Image(systemName: record.type == .workOrder ? "wrench.fill" : "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(color)
        }
    }

    func priorityColor(_ p: WorkOrderPriority) -> Color {
        switch p {
        case .critical: return Color(hex: "EF4444")
        case .high:     return FleetTheme.accentOrange
        case .medium:   return FleetTheme.accentBlue
        case .low:      return FleetTheme.accent
        }
    }

    var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "tray")
                .font(.system(size: 36))
                .foregroundStyle(.gray)
            Text("No records found")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

// MARK: - Record Card

struct MaintenanceRecordCard: View {

    let record: MaintenanceHistoryView.MaintenanceRecord
    @State private var expanded = false

    var priorityColor: Color {
        switch record.priority {
        case .critical: return Color(hex: "EF4444")
        case .high:     return FleetTheme.accentOrange
        case .medium:   return FleetTheme.accentBlue
        case .low:      return FleetTheme.accent
        }
    }

    var priorityLabel: String {
        switch record.priority {
        case .critical: return "Critical"
        case .high:     return "High"
        case .medium:   return "Medium"
        case .low:      return "Low"
        }
    }

    var typeLabel: String {
        record.type == .workOrder ? "Work Order" : "Task"
    }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: record.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                    expanded.toggle()
                }
            } label: {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        // Type badge
                        Text(typeLabel)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(record.type == .workOrder ? FleetTheme.accentPurple : FleetTheme.accentBlue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background((record.type == .workOrder ? FleetTheme.accentPurple : FleetTheme.accentBlue).opacity(0.12))
                            .clipShape(Capsule())

                        // Priority badge
                        HStack(spacing: 4) {
                            Circle().fill(priorityColor).frame(width: 6, height: 6)
                            Text(priorityLabel)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(priorityColor)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(priorityColor.opacity(0.1))
                        .clipShape(Capsule())

                        Spacer()

                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.gray)
                    }

                    Text(record.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 16) {
                        metaChip(icon: "calendar", text: formattedDate)
                        metaChip(icon: "gauge.with.dots.needle.bottom.50percent", text: record.odometer)
                        metaChip(icon: "clock", text: String(format: "%.1fh", record.hoursSpent))
                    }
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded Detail
            if expanded {
                Divider()
                    .background(Color.white.opacity(0.07))
                    .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 16) {

                    // Issue Resolved
                    detailBlock(
                        icon: "doc.text.fill",
                        iconColor: FleetTheme.accentBlue,
                        label: "Issue Resolved",
                        content: record.issueResolved
                    )

                    // Technician
                    detailBlock(
                        icon: "person.fill",
                        iconColor: FleetTheme.accentPurple,
                        label: "Technician",
                        content: record.technicianName
                    )

                    // Parts Used
                    if !record.parts.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Parts Used", systemImage: "shippingbox.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.gray)

                            VStack(spacing: 6) {
                                ForEach(record.parts) { part in
                                    HStack {
                                        Text(part.name)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Text("×\(part.quantity)")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.gray)
                                        Text("₹\(part.unitCost * Double(part.quantity), specifier: "%.0f")")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(FleetTheme.accentOrange)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.04))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                            }
                        }
                    }

                    // Notes
                    if let notes = record.notes {
                        detailBlock(
                            icon: "note.text",
                            iconColor: FleetTheme.accent,
                            label: "Notes",
                            content: notes
                        )
                    }

                    // Total Cost
                    HStack {
                        Text("Total Cost")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        Text("₹\(record.cost, specifier: "%.0f")")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(FleetTheme.accentOrange)
                    }
                    .padding(14)
                    .background(FleetTheme.accentOrange.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(FleetTheme.accentOrange.opacity(0.15), lineWidth: 1)
                    )
                }
                .padding(16)
            }
        }
        .background(FleetTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(expanded ? priorityColor.opacity(0.25) : FleetTheme.cardBorder, lineWidth: 1)
        )
        .frame(maxWidth: .infinity)
    }

    func metaChip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 10)).foregroundStyle(.gray)
            Text(text).font(.system(size: 11)).foregroundStyle(.gray)
        }
    }

    func detailBlock(icon: String, iconColor: Color, label: String, content: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 30, height: 30)
                Image(systemName: icon).font(.system(size: 12)).foregroundStyle(iconColor)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.gray)
                Text(content)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MaintenanceHistoryView(
            vehicle: Vehicle(
                id: UUID(),
                make: "Ford",
                model: "F-150",
                year: 2024,
                vin: "1FTFW1ET5EKE00001",
                licensePlate: "TRK-001",
                assignedDriverId: nil,
                status: .active
            )
        )
    }
    .preferredColorScheme(.dark)
}
