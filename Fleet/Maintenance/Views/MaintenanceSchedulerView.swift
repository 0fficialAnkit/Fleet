import SwiftUI
import Supabase

// ═══════════════════════════════════════════════════════════════
// MARK: - Main Screen
// ═══════════════════════════════════════════════════════════════

struct MaintenanceSchedulerView: View {
    @State private var viewModel = MaintenanceSchedulerViewModel()
    @Namespace private var calendarNS
    @State private var selectedTask: ScheduledTask? = nil
    @State private var selectedWorkOrder: ScheduledWorkOrder? = nil
    @Environment(AuthViewModel.self) private var authViewModel

    init() {
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(themeModel.maintenancePrimary)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor(themeModel.textSecondary)], for: .normal)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Calendar strip
                        CalendarStripView(viewModel: viewModel, namespace: calendarNS)

                        // Segmented Control
                        SchedulerSegmentedControl(viewModel: viewModel)

                        // Task / Work Order List
                        TaskListSection(
                            viewModel: viewModel,
                            selectedTask: $selectedTask,
                            selectedWorkOrder: $selectedWorkOrder
                        )
                    }
                }
            }
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(item: $selectedTask) { task in
                TaskDetailSheet(task: task, viewModel: viewModel)
            }
            .navigationDestination(item: $selectedWorkOrder) { wo in
                WorkOrderDetailView(scheduledWorkOrder: wo)
            }
            .task {
                viewModel.currentUserId = authViewModel.currentUser?.id
                await viewModel.loadData()
                viewModel.setupRealtime()
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Calendar Strip
// ═══════════════════════════════════════════════════════════════

private struct CalendarStripView: View {
    let viewModel: MaintenanceSchedulerViewModel
    let namespace: Namespace.ID

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.calendarDays, id: \.self) { date in
                        DayCell(
                            date: date,
                            isToday: viewModel.isToday(date),
                            isSelected: viewModel.isSelected(date),
                            taskCount: viewModel.taskCountForDate[Calendar.current.startOfDay(for: date)] ?? 0,
                            namespace: namespace
                        )
                        .id(date)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                                viewModel.selectedDate = Calendar.current.startOfDay(for: date)
                            }
                        }
                    }
                }
                .padding(.horizontal, themeModel.spacingMD)
                .padding(.vertical, themeModel.spacingMD)
            }
            .onAppear {
                let today = Calendar.current.startOfDay(for: Date())
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        proxy.scrollTo(today, anchor: .center)
                    }
                }
            }
        }
        .padding(.horizontal, themeModel.spacingMD)
        .padding(.top, themeModel.spacingSM)
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Day Cell
// ═══════════════════════════════════════════════════════════════

private struct DayCell: View {
    let date: Date
    let isToday: Bool
    let isSelected: Bool
    let taskCount: Int
    let namespace: Namespace.ID

    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.4

    private var dayName: String {
        let f = DateFormatter(); f.dateFormat = "EEE"; return f.string(from: date).uppercased()
    }
    private var dayNumber: String {
        let f = DateFormatter(); f.dateFormat = "d"; return f.string(from: date)
    }
    private var labelColor: Color { isSelected ? themeModel.maintenancePrimary : themeModel.textTertiary }
    private var numberColor: Color { isSelected ? themeModel.textPrimary : themeModel.textSecondary }

    var body: some View {
        VStack(spacing: 6) {
            Text(dayName)
                .font(themeModel.small())
                .foregroundStyle(labelColor)
                .animation(.easeInOut(duration: 0.25), value: isSelected)

            Text(dayNumber)
                .font(isSelected ? themeModel.title(20) : themeModel.headline())
                .foregroundStyle(numberColor)
                .animation(.spring(response: 0.3), value: isSelected)

            // Combined event dot indicator
            Circle()
                .fill(taskCount > 0 ? themeModel.maintenancePrimary : Color.clear)
                .frame(width: 5, height: 5)
        }
        .frame(width: 54, height: 72)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous)
                    .fill(themeModel.maintenancePrimary.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous)
                            .stroke(themeModel.maintenancePrimary.opacity(0.4), lineWidth: 1.2)
                    )
                    .matchedGeometryEffect(id: "calendarSelectedBG", in: namespace)
            }
        }
        .overlay {
            if isToday && !isSelected {
                RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous)
                    .stroke(themeModel.accent.opacity(pulseOpacity), lineWidth: 1.5)
                    .scaleEffect(pulseScale)
                    .onAppear { startPulse() }
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous))
    }

    private func startPulse() {
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
            pulseScale = 1.07
            pulseOpacity = 0.9
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Premium sliding Segmented Control
// ═══════════════════════════════════════════════════════════════

private struct SchedulerSegmentedControl: View {
    @Bindable var viewModel: MaintenanceSchedulerViewModel

    var body: some View {
        Picker("Tabs", selection: $viewModel.selectedTab) {
            ForEach(SchedulerTabType.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, themeModel.spacingMD)
        .padding(.vertical, themeModel.spacingMD)
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Task List Section
// ═══════════════════════════════════════════════════════════════

private struct TaskListSection: View {
    let viewModel: MaintenanceSchedulerViewModel
    @Binding var selectedTask: ScheduledTask?
    @Binding var selectedWorkOrder: ScheduledWorkOrder?

    private var dateTitle: String {
        if Calendar.current.isDateInToday(viewModel.selectedDate) { return "Today" }
        if Calendar.current.isDateInYesterday(viewModel.selectedDate) { return "Yesterday" }
        if Calendar.current.isDateInTomorrow(viewModel.selectedDate) { return "Tomorrow" }
        let f = DateFormatter(); f.dateFormat = "EEEE, d MMM"; return f.string(from: viewModel.selectedDate)
    }

    private var itemsCount: Int {
        viewModel.selectedTab == .tasks ? viewModel.tasksForSelectedDate.count : viewModel.workOrdersForSelectedDate.count
    }

    var body: some View {
        LazyVStack(spacing: themeModel.spacingMD) {
            // Section Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dateTitle)
                        .font(themeModel.headline())
                        .foregroundStyle(themeModel.textPrimary)
                    Text("\(itemsCount) \(viewModel.selectedTab.rawValue.lowercased()) assigned")
                        .font(themeModel.caption())
                        .foregroundStyle(themeModel.textTertiary)
                }
                Spacer()
                if itemsCount > 0 {
                    StatusLegendChip()
                }
            }
            .padding(.horizontal, themeModel.spacingMD)
            .padding(.top, themeModel.spacingMD)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.selectedDate)

            if viewModel.selectedTab == .tasks {
                if viewModel.tasksForSelectedDate.isEmpty {
                    EmptyScheduleView(title: "No Tasks Scheduled", message: "No maintenance tasks assigned for this day.")
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity
                        ))
                } else {
                    ForEach(viewModel.tasksForSelectedDate) { task in
                        TaskCard(task: task)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedTask = task }
                            .scrollTransition { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1 : 0.7)
                                    .scaleEffect(phase.isIdentity ? 1 : 0.96)
                                    .offset(y: phase.isIdentity ? 0 : 8)
                            }
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                removal: .opacity
                            ))
                    }
                    .padding(.horizontal, themeModel.spacingMD)
                }
            } else {
                if viewModel.workOrdersForSelectedDate.isEmpty {
                    EmptyScheduleView(title: "No Work Orders", message: "No service work orders created on this date.")
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity
                        ))
                } else {
                    ForEach(viewModel.workOrdersForSelectedDate) { workOrder in
                        WorkOrderCard(workOrder: workOrder)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedWorkOrder = workOrder }
                            .scrollTransition { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1 : 0.7)
                                    .scaleEffect(phase.isIdentity ? 1 : 0.96)
                                    .offset(y: phase.isIdentity ? 0 : 8)
                            }
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                removal: .opacity
                            ))
                    }
                    .padding(.horizontal, themeModel.spacingMD)
                }
            }

            Spacer(minLength: 60)
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.78), value: viewModel.selectedDate)
        .animation(.spring(response: 0.35, dampingFraction: 0.76), value: viewModel.selectedTab)
    }
}

// MARK: - Status Legend Chip
private struct StatusLegendChip: View {
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(themeModel.danger).frame(width: 6, height: 6)
            Circle().fill(themeModel.warning).frame(width: 6, height: 6)
            Circle().fill(themeModel.success).frame(width: 6, height: 6)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(themeModel.surfaceTertiary.opacity(0.6))
        .clipShape(Capsule())
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Task Card
// ═══════════════════════════════════════════════════════════════

private struct TaskCard: View {
    let task: ScheduledTask
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Priority accent bar + header
            HStack(spacing: themeModel.spacingMD) {
                VStack(alignment: .leading, spacing: themeModel.spacingMD) {
                    // Top row
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(task.vehicleName)
                                .font(themeModel.headline())
                                .foregroundStyle(themeModel.textPrimary)
                            Text(task.vehicleNumber)
                                .font(themeModel.caption())
                                .foregroundStyle(themeModel.textTertiary)
                        }
                        Spacer()
                        StatusBadge(text: task.status.rawValue, color: statusColor(task.status))
                    }

                    // Task type
                    Text(taskTypeLabel(task.taskType))
                        .font(themeModel.bodyMedium())
                        .foregroundStyle(themeModel.maintenancePrimary)

                    // Info row
                    HStack(spacing: themeModel.spacingMD) {
                        InfoPill(icon: "clock",                text: task.scheduledTime)
                        InfoPill(icon: "timer",                text: task.estimatedDuration)
                        InfoPill(icon: priorityIconName(task.priority), text: task.priority.rawValue, color: priorityColor(task.priority))
                    }

                    // Assigned by
                    HStack(spacing: 5) {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                            .foregroundStyle(themeModel.textTertiary)
                        Text("Assigned by \(task.assignedBy)")
                            .font(themeModel.caption())
                            .foregroundStyle(themeModel.textTertiary)
                    }
                }
                .padding(.vertical, themeModel.spacingMD)
                .padding(.trailing, themeModel.spacingMD)
                .padding(.leading, themeModel.spacingMD)
            }
        }
        .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                .stroke(statusColor(task.status).opacity(0.5), lineWidth: 1.0)
        )
        .shadow(
            color: statusColor(task.status).opacity(0.15),
            radius: 8,
            y: 4
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Work Order Card
// ═══════════════════════════════════════════════════════════════

private struct WorkOrderCard: View {
    let workOrder: ScheduledWorkOrder
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: themeModel.spacingMD) {
                VStack(alignment: .leading, spacing: themeModel.spacingMD) {
                    // Header row
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("WO-\(workOrder.id.uuidString.prefix(6).uppercased())")
                                .font(themeModel.headline())
                                .foregroundStyle(themeModel.textPrimary)
                            Text("\(workOrder.vehicleName) · \(workOrder.vehicleNumber)")
                                .font(themeModel.caption())
                                .foregroundStyle(themeModel.textTertiary)
                        }
                        Spacer()
                        StatusBadge(
                            text: statusLabel(workOrder.status),
                            color: statusColor(workOrder.status)
                        )
                    }

                    // Labor & Assigned Row
                    HStack(spacing: themeModel.spacingMD) {
                        InfoPill(icon: "person.fill", text: "By: \(workOrder.assignedBy)")
                        InfoPill(icon: "clock.fill",  text: workOrder.laborHours)
                        InfoPill(icon: "dollarsign.circle.fill", text: workOrder.laborCost, color: themeModel.success)
                    }

                    // Spare parts consumed (if any)
                    if !workOrder.partsUsed.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(themeModel.maintenancePrimary)
                            Text(workOrder.partsUsed.joined(separator: ", "))
                                .font(themeModel.small())
                                .foregroundStyle(themeModel.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.vertical, themeModel.spacingMD)
                .padding(.trailing, themeModel.spacingMD)
                .padding(.leading, themeModel.spacingMD)
            }
        }
        .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                .stroke(statusColor(workOrder.status).opacity(0.5), lineWidth: 1.0)
        )
        .shadow(
            color: statusColor(workOrder.status).opacity(0.15),
            radius: 8,
            y: 4
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }

    func statusLabel(_ status: WorkOrderStatus) -> String {
        switch status {
        case .open:       return "Open"
        case .inProgress: return "In Progress"
        case .completed:  return "Completed"
        case .cancelled:  return "Cancelled"
        }
    }

    func statusColor(_ status: WorkOrderStatus) -> Color {
        switch status {
        case .open:       return themeModel.info
        case .inProgress: return themeModel.warning
        case .completed:  return themeModel.success
        case .cancelled:  return themeModel.danger
        }
    }

    func priorityColor(_ priority: WorkOrderPriority) -> Color {
        switch priority {
        case .low:      return themeModel.success
        case .medium:   return themeModel.info
        case .high:     return themeModel.warning
        case .critical: return themeModel.danger
        }
    }
}

// MARK: - Info Pill
private struct InfoPill: View {
    let icon: String
    let text: String
    var color: Color = themeModel.textSecondary

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(color)
            Text(text)
                .font(themeModel.small())
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Empty State
// ═══════════════════════════════════════════════════════════════

private struct EmptyScheduleView: View {
    let title: String
    let message: String
    @State private var floatOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: themeModel.spacingLG) {
            ZStack {
                Circle()
                    .fill(themeModel.maintenancePrimary.opacity(0.08))
                    .frame(width: 120, height: 120)

                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(themeModel.maintenancePrimary.opacity(0.6))
                    .symbolEffect(.pulse)
                    .offset(y: floatOffset)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                            floatOffset = -8
                        }
                    }
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(themeModel.headline())
                    .foregroundStyle(themeModel.textPrimary)
                Text(message)
                    .font(themeModel.body())
                    .foregroundStyle(themeModel.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, themeModel.spacingXXL + 20)
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Task Detail Sheet
// ═══════════════════════════════════════════════════════════════

struct TaskDetailSheet: View {
    let task: ScheduledTask
    let viewModel: MaintenanceSchedulerViewModel

    @State private var repairNotes: String = ""
    @State private var showActionConfirm = false
    @State private var confirmAction: TaskDisplayStatus? = nil

    var body: some View {
        ZStack {
            themeModel.backgroundPrimary.ignoresSafeArea()

            ScrollView {
                    VStack(spacing: themeModel.spacingLG) {

                        // MARK: Status Banner
                        let currentTask = viewModel.allTasks.first(where: { $0.id == task.id }) ?? task
                        HStack(spacing: themeModel.spacingMD) {
                            Image(systemName: statusIcon(currentTask.status))
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(statusColor(currentTask.status))
                                .symbolEffect(.pulse, isActive: currentTask.status == .critical)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(currentTask.vehicleName)
                                    .font(themeModel.headline())
                                    .foregroundStyle(themeModel.textPrimary)
                                Text(currentTask.vehicleNumber)
                                    .font(themeModel.caption())
                                    .foregroundStyle(themeModel.textTertiary)
                            }
                            Spacer()
                            StatusBadge(text: currentTask.status.rawValue, color: statusColor(currentTask.status))
                        }
                        .padding(themeModel.spacingMD)
                        .background(statusColor(currentTask.status).opacity(0.09))
                        .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                                .stroke(statusColor(currentTask.status).opacity(0.3), lineWidth: 1)
                        )

                        // MARK: Vehicle Details
                        SheetSection(title: "Task Details") {
                            InfoRow(icon: "car.fill",      label: "Vehicle",   value: "\(currentTask.vehicleName) · \(currentTask.vehicleNumber)")
                            Divider().background(themeModel.divider)
                            InfoRow(icon: "wrench.fill",   label: "Type",      value: taskTypeLabel(currentTask.taskType))
                            Divider().background(themeModel.divider)
                            InfoRow(icon: "flag.fill",     label: "Priority",  value: currentTask.priority.rawValue, valueColor: priorityColor(currentTask.priority))
                            Divider().background(themeModel.divider)
                            InfoRow(icon: "clock.fill",    label: "Time",      value: "\(currentTask.scheduledTime) · \(currentTask.estimatedDuration)")
                            Divider().background(themeModel.divider)
                            InfoRow(icon: "person.fill",   label: "Assigned By", value: currentTask.assignedBy)
                        }

                        // MARK: Service Checklist
                        SheetSection(title: "Service Checklist") {
                            let items = currentTask.checklistItems
                            let doneCount = items.filter(\.isChecked).count
                            let totalCount = items.count

                            HStack {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4).fill(themeModel.surfaceTertiary).frame(height: 6)
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(themeModel.success)
                                            .frame(width: totalCount > 0 ? geo.size.width * CGFloat(doneCount) / CGFloat(totalCount) : 0, height: 6)
                                    }
                                }
                                .frame(height: 6)

                                Text("\(doneCount)/\(totalCount)")
                                    .font(themeModel.caption())
                                    .foregroundStyle(themeModel.textTertiary)
                                    .frame(width: 36, alignment: .trailing)
                            }

                            Divider().background(themeModel.divider)

                            ForEach(items) { item in
                                ChecklistRow(item: item) {
                                    viewModel.toggleChecklist(taskId: currentTask.id, itemId: item.id)
                                }
                                if item.id != items.last?.id {
                                    Divider().background(themeModel.divider).padding(.leading, 32)
                                }
                            }
                        }

                        // MARK: Parts Needed
                        if !currentTask.partsNeeded.isEmpty {
                            SheetSection(title: "Spare Parts Needed") {
                                ForEach(Array(currentTask.partsNeeded.enumerated()), id: \.offset) { idx, part in
                                    HStack(spacing: themeModel.spacingMD) {
                                        Image(systemName: "gearshape.fill")
                                            .foregroundStyle(themeModel.maintenancePrimary)
                                            .frame(width: 20)
                                        Text(part)
                                            .font(themeModel.body())
                                            .foregroundStyle(themeModel.textPrimary)
                                        Spacer()
                                    }
                                    if idx < currentTask.partsNeeded.count - 1 {
                                        Divider().background(themeModel.divider)
                                    }
                                }
                            }
                        }

                        // MARK: Repair Notes
                        SheetSection(title: "Service Notes") {
                            TextField("Add notes, observations, or findings...", text: $repairNotes, axis: .vertical)
                                .lineLimit(3...6)
                                .font(themeModel.body())
                                .foregroundStyle(themeModel.textPrimary)
                        }

                        // MARK: Previous History
                        SheetSection(title: "Previous History") {
                            HStack(alignment: .top, spacing: themeModel.spacingMD) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundStyle(themeModel.textTertiary)
                                    .frame(width: 20)
                                Text(currentTask.previousNote)
                                    .font(themeModel.body())
                                    .foregroundStyle(themeModel.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        // MARK: AI Recommendation
                        SheetSection(title: "AI Recommendation") {
                            HStack(alignment: .top, spacing: themeModel.spacingMD) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(themeModel.warning)
                                    .font(.system(size: 18, weight: .semibold))
                                Text(currentTask.aiRecommendation)
                                    .font(themeModel.body())
                                    .foregroundStyle(themeModel.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        // MARK: Action Buttons
                        VStack(spacing: themeModel.spacingMD) {
                            if currentTask.status == .pending || currentTask.status == .delayed {
                                SheetActionButton(title: "Start Task", icon: "play.circle.fill", color: themeModel.maintenancePrimary) {
                                    viewModel.updateTaskStatus(id: currentTask.id, to: .inProgress)
                                }
                            }
                            if currentTask.status == .inProgress || currentTask.status == .critical {
                                SheetActionButton(title: "Mark as Completed", icon: "checkmark.circle.fill", color: themeModel.success) {
                                    viewModel.updateTaskStatus(id: currentTask.id, to: .completed)
                                }
                            }
                            if currentTask.status != .completed && currentTask.status != .delayed {
                                SheetActionButton(title: "Report Issue / Delay", icon: "exclamationmark.triangle.fill", color: themeModel.warning) {
                                    viewModel.updateTaskStatus(id: currentTask.id, to: .delayed)
                                }
                            }

                            HStack(spacing: themeModel.spacingMD) {
                                SheetSecondaryButton(title: "Add Photos", icon: "camera")
                                SheetSecondaryButton(title: "Voice Note", icon: "mic.circle")
                            }
                        }
                        .padding(.bottom, themeModel.spacingLG)
                    }
                    .padding(themeModel.spacingMD)
            }
        }
        .navigationTitle(task.vehicleName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Work Order Detail Sheet
// ═══════════════════════════════════════════════════════════════

struct WorkOrderDetailSheet: View {
    let workOrder: ScheduledWorkOrder
    let viewModel: MaintenanceSchedulerViewModel

    @State private var notes: String = ""
    @State private var showAddPartSheet = false
    @State private var newPartName: String = ""

    private var currentWO: ScheduledWorkOrder {
        viewModel.allWorkOrders.first(where: { $0.id == workOrder.id }) ?? workOrder
    }

    var body: some View {
        ZStack {
            themeModel.backgroundPrimary.ignoresSafeArea()

            ScrollView {
                    VStack(spacing: themeModel.spacingLG) {

                        // MARK: Status Banner
                        HStack(spacing: themeModel.spacingMD) {
                            Image(systemName: statusIcon(currentWO.status))
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(statusColor(currentWO.status))

                            VStack(alignment: .leading, spacing: 3) {
                                Text("WO-\(currentWO.id.uuidString.prefix(8).uppercased())")
                                    .font(themeModel.headline())
                                    .foregroundStyle(themeModel.textPrimary)
                                Text("\(currentWO.vehicleName) · \(currentWO.vehicleNumber)")
                                    .font(themeModel.caption())
                                    .foregroundStyle(themeModel.textTertiary)
                            }
                            Spacer()
                            StatusBadge(text: statusLabel(currentWO.status), color: statusColor(currentWO.status))
                        }
                        .padding(themeModel.spacingMD)
                        .background(statusColor(currentWO.status).opacity(0.09))
                        .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                                .stroke(statusColor(currentWO.status).opacity(0.3), lineWidth: 1)
                        )

                        // MARK: Work Order Details
                        SheetSection(title: "Order Details") {
                            InfoRow(icon: "number",        label: "Order ID",    value: "WO-\(currentWO.id.uuidString.prefix(8).uppercased())")
                            Divider().background(themeModel.divider)
                            InfoRow(icon: "car.fill",      label: "Vehicle",     value: "\(currentWO.vehicleName) · \(currentWO.vehicleNumber)")
                            Divider().background(themeModel.divider)
                            InfoRow(icon: "flag.fill",     label: "Priority",    value: priorityLabel(currentWO.priority), valueColor: priorityColor(currentWO.priority))
                            Divider().background(themeModel.divider)
                            InfoRow(icon: "person.fill",   label: "Assigned To",  value: currentWO.assignedBy)
                            Divider().background(themeModel.divider)
                            InfoRow(icon: "calendar",      label: "Created At",   value: currentWO.createdAt.formatted(date: .abbreviated, time: .shortened))
                        }

                        // MARK: Spare Parts Consumed
                        SheetSection(title: "Parts Consumed") {
                            Button(action: { showAddPartSheet = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(themeModel.maintenancePrimary)
                                    Text("Add Part from Inventory")
                                        .font(themeModel.bodyMedium())
                                        .foregroundStyle(themeModel.maintenancePrimary)
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)

                            if !currentWO.partsUsed.isEmpty {
                                Divider().background(themeModel.divider)

                                ForEach(Array(currentWO.partsUsed.enumerated()), id: \.offset) { idx, part in
                                    HStack(spacing: themeModel.spacingMD) {
                                        Image(systemName: "gearshape.2.fill")
                                            .foregroundStyle(themeModel.maintenancePrimary)
                                            .frame(width: 20)
                                        Text(part)
                                            .font(themeModel.body())
                                            .foregroundStyle(themeModel.textPrimary)
                                        Spacer()
                                    }
                                    if idx < currentWO.partsUsed.count - 1 {
                                        Divider().background(themeModel.divider)
                                    }
                                }
                            }
                        }

                        // MARK: Labor & Financials
                        SheetSection(title: "Labor & Financials") {
                            HStack(spacing: themeModel.spacingMD) {
                                LaborStatBox(label: "Est. Hours", value: currentWO.laborHours, icon: "clock.fill",  color: themeModel.info)
                                LaborStatBox(label: "Labor Cost",  value: currentWO.laborCost,   icon: "dollarsign.circle.fill",  color: themeModel.success)
                            }
                        }

                        // MARK: Notes Section
                        SheetSection(title: "Service Notes") {
                            TextField("Add order details, notes or observations...", text: $notes, axis: .vertical)
                                .lineLimit(3...6)
                                .font(themeModel.body())
                                .foregroundStyle(themeModel.textPrimary)
                                .onChange(of: notes) { _, newValue in
                                    viewModel.updateWorkOrderNotes(id: currentWO.id, notes: newValue)
                                }
                                .onAppear {
                                    notes = currentWO.notes
                                }
                        }

                        // MARK: Action Buttons
                        VStack(spacing: themeModel.spacingMD) {
                            if currentWO.status == .open {
                                SheetActionButton(title: "Start Work Order", icon: "play.circle.fill", color: themeModel.maintenancePrimary) {
                                    viewModel.updateWorkOrderStatus(id: currentWO.id, to: .inProgress)
                                }
                            }
                            if currentWO.status == .inProgress {
                                SheetActionButton(title: "Mark as Completed", icon: "checkmark.circle.fill", color: themeModel.success) {
                                    viewModel.updateWorkOrderStatus(id: currentWO.id, to: .completed)
                                }
                            }
                            if currentWO.status == .completed {
                                SheetActionButton(title: "Reopen Work Order", icon: "arrow.counterclockwise.circle.fill", color: themeModel.warning) {
                                    viewModel.updateWorkOrderStatus(id: currentWO.id, to: .inProgress)
                                }
                            }
                            if currentWO.status != .cancelled && currentWO.status != .completed {
                                SheetActionButton(title: "Cancel Work Order", icon: "xmark.circle.fill", color: themeModel.danger) {
                                    viewModel.updateWorkOrderStatus(id: currentWO.id, to: .cancelled)
                                }
                            }
                        }
                        .padding(.bottom, themeModel.spacingLG)
                    }
                    .padding(themeModel.spacingMD)
            }
        }
        .navigationTitle("Work Order Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddPartSheet) {
                ZStack {
                    themeModel.backgroundPrimary.ignoresSafeArea()
                    VStack(spacing: 20) {
                        Text("Add Spare Part")
                            .font(themeModel.headline())
                            .foregroundStyle(themeModel.textPrimary)
                            .padding(.top, 20)

                        TextField("Part Name (e.g. Air Filter)", text: $newPartName)
                            .font(themeModel.body())
                            .padding(12)
                            .background(themeModel.surfaceTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal)

                        Button(action: {
                            if !newPartName.isEmpty {
                                viewModel.addPartToWorkOrder(id: currentWO.id, part: newPartName)
                                newPartName = ""
                                showAddPartSheet = false
                            }
                        }) {
                            Text("Add to Consumed Parts")
                                .font(themeModel.headline())
                                .foregroundStyle(themeModel.textPrimary)
                                .padding()
                                .frame(maxWidth: .infinity)
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

    func statusIcon(_ status: WorkOrderStatus) -> String {
        switch status {
        case .open:       return "tray.circle"
        case .inProgress: return "wrench.adjustable"
        case .completed:  return "checkmark.circle.fill"
        case .cancelled:  return "xmark.circle.fill"
        }
    }

    func statusLabel(_ status: WorkOrderStatus) -> String {
        switch status {
        case .open:       return "Open"
        case .inProgress: return "In Progress"
        case .completed:  return "Completed"
        case .cancelled:  return "Cancelled"
        }
    }

    func statusColor(_ status: WorkOrderStatus) -> Color {
        switch status {
        case .open:       return themeModel.info
        case .inProgress: return themeModel.warning
        case .completed:  return themeModel.success
        case .cancelled:  return themeModel.danger
        }
    }

    func priorityLabel(_ priority: WorkOrderPriority) -> String {
        switch priority {
        case .low:      return "Low"
        case .medium:   return "Medium"
        case .high:     return "High"
        case .critical: return "Critical"
        }
    }

    func priorityColor(_ priority: WorkOrderPriority) -> Color {
        switch priority {
        case .low:      return themeModel.success
        case .medium:   return themeModel.info
        case .high:     return themeModel.warning
        case .critical: return themeModel.danger
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Sheet Section Wrapper
// ═══════════════════════════════════════════════════════════════

private struct SheetSection<Content: View>: View {
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

// ═══════════════════════════════════════════════════════════════
// MARK: - Checklist Row
// ═══════════════════════════════════════════════════════════════

private struct ChecklistRow: View {
    let item: ChecklistItem
    let onToggle: () -> Void

    var body: some View {
        Button(action: { withAnimation(.spring(response: 0.3)) { onToggle() } }) {
            HStack(spacing: themeModel.spacingMD) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isChecked ? themeModel.success : themeModel.textDisabled)
                    .font(.system(size: 20))
                    .symbolEffect(.bounce, value: item.isChecked)

                Text(item.title)
                    .font(themeModel.body())
                    .foregroundStyle(item.isChecked ? themeModel.textTertiary : themeModel.textPrimary)
                    .strikethrough(item.isChecked, color: themeModel.textTertiary)
                    .animation(.easeInOut(duration: 0.2), value: item.isChecked)

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Sheet Action Button (Primary)
// ═══════════════════════════════════════════════════════════════

private struct SheetActionButton: View {
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
                    .stroke(color.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.2), radius: 8, y: 4)
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Sheet Secondary Button
// ═══════════════════════════════════════════════════════════════

private struct SheetSecondaryButton: View {
    let title: String
    let icon: String

    var body: some View {
        Button(action: {}) {
            HStack(spacing: themeModel.spacingSM) {
                Image(systemName: icon)
                Text(title)
            }
            .font(themeModel.bodyMedium())
            .foregroundStyle(themeModel.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(themeModel.spacingMD)
            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Labor Stat Box
// ═══════════════════════════════════════════════════════════════

private struct LaborStatBox: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: themeModel.spacingSM) {
            Image(systemName: icon)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(themeModel.headline())
                    .foregroundStyle(themeModel.textPrimary)
                Text(label)
                    .font(themeModel.caption())
                    .foregroundStyle(themeModel.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(themeModel.spacingMD)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous))
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Shared Helpers
// ═══════════════════════════════════════════════════════════════

func statusColor(_ status: TaskDisplayStatus) -> Color {
    switch status {
    case .pending:    return themeModel.info
    case .inProgress: return themeModel.warning
    case .completed:  return themeModel.success
    case .delayed:    return themeModel.danger
    case .critical:   return themeModel.danger
    }
}

func statusIcon(_ status: TaskDisplayStatus) -> String {
    switch status {
    case .pending:    return "hourglass"
    case .inProgress: return "wrench.adjustable.fill"
    case .completed:  return "checkmark.seal.fill"
    case .delayed:    return "exclamationmark.triangle.fill"
    case .critical:   return "exclamationmark.2"
    }
}

func priorityColor(_ priority: TaskPriority) -> Color {
    switch priority {
    case .low:       return themeModel.success
    case .medium:    return themeModel.info
    case .high:      return themeModel.warning
    case .emergency: return themeModel.danger
    }
}

func priorityIconName(_ priority: TaskPriority) -> String {
    switch priority {
    case .low:       return "arrow.down.circle"
    case .medium:    return "minus.circle"
    case .high:      return "arrow.up.circle"
    case .emergency: return "exclamationmark.2"
    }
}

func taskTypeLabel(_ type: MaintenanceTaskType) -> String {
    switch type {
    case .oilChange:    return "Oil Change"
    case .tireRotation: return "Tyre Rotation"
    case .inspection:   return "Safety Inspection"
    case .repair:       return "Repair"
    case .other:        return "Other Service"
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Preview
// ═══════════════════════════════════════════════════════════════

#Preview {
    MaintenanceSchedulerView()
}
