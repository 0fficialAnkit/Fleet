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
    @State private var isShowingCreateTaskSheet = false
    @Environment(AuthViewModel.self) private var authViewModel

    init() {
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(Color.brown)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor(Color.secondary)], for: .normal)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

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
                WorkOrderDetailSheet(workOrder: wo, viewModel: viewModel)
            }
            .toolbar {
                if viewModel.selectedTab == .tasks {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isShowingCreateTaskSheet = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color.brown)
                                .frame(width: 32, height: 32)
                                .background(Color.brown.opacity(0.12), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .sheet(isPresented: $isShowingCreateTaskSheet) {
                CreateTaskSheet(viewModel: viewModel, initialDate: viewModel.selectedDate, currentUserId: authViewModel.currentUser?.id)
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
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
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
        .padding(.horizontal, 16)
        .padding(.top, 8)
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
    private var labelColor: Color { isSelected ? Color.brown : Color(.tertiaryLabel) }
    private var numberColor: Color { isSelected ? Color.primary : Color.secondary }

    var body: some View {
        VStack(spacing: 6) {
            Text(dayName)
                .font(.caption.weight(.medium))
                .foregroundStyle(labelColor)
                .animation(.easeInOut(duration: 0.25), value: isSelected)

            Text(dayNumber)
                .font(isSelected ? .title3.bold() : .headline)
                .foregroundStyle(numberColor)
                .animation(.spring(response: 0.3), value: isSelected)

            // Combined event dot indicator
            Circle()
                .fill(taskCount > 0 ? Color.brown : Color.clear)
                .frame(width: 5, height: 5)
        }
        .frame(width: 54, height: 72)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.brown.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.brown.opacity(0.4), lineWidth: 1.2)
                    )
                    .matchedGeometryEffect(id: "calendarSelectedBG", in: namespace)
            }
        }
        .overlay {
            if isToday && !isSelected {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.teal.opacity(pulseOpacity), lineWidth: 1.5)
                    .scaleEffect(pulseScale)
                    .onAppear { startPulse() }
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
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
        LazyVStack(spacing: 16) {
            // Section Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dateTitle)
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                    Text("\(itemsCount) \(viewModel.selectedTab.rawValue.lowercased()) assigned")
                        .font(.footnote)
                        .foregroundStyle(Color(.tertiaryLabel))
                }
                Spacer()
                if itemsCount > 0 {
                    StatusLegendChip()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
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
                        Button {
                            selectedTask = task
                        } label: {
                            TaskCard(task: task)
                        }
                        .buttonStyle(ScaleButtonStyle())
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
                    .padding(.horizontal, 16)
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
                        Button {
                            selectedWorkOrder = workOrder
                        } label: {
                            WorkOrderCard(workOrder: workOrder)
                        }
                        .buttonStyle(ScaleButtonStyle())
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
                    .padding(.horizontal, 16)
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
            Circle().fill(Color.red).frame(width: 6, height: 6)
            Circle().fill(Color.yellow).frame(width: 6, height: 6)
            Circle().fill(Color.green).frame(width: 6, height: 6)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.tertiarySystemBackground).opacity(0.6))
        .clipShape(Capsule())
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Task Card
// ═══════════════════════════════════════════════════════════════

private struct TaskCard: View {
    let task: ScheduledTask

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Priority accent bar + header
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 16) {
                    // Top row
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(task.vehicleName)
                                .font(.headline)
                                .foregroundStyle(Color.primary)
                            Text(task.vehicleNumber)
                                .font(.footnote)
                                .foregroundStyle(Color(.tertiaryLabel))
                        }
                        Spacer()
                        StatusBadge(text: task.status.rawValue, color: statusColor(task.status))
                    }

                    // Task type
                    Text(taskTypeLabel(task.taskType))
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.brown)

                    // Info row
                    HStack(spacing: 16) {
                        InfoPill(icon: "clock",                text: task.scheduledTime)
                        InfoPill(icon: "timer",                text: task.estimatedDuration)
                        InfoPill(icon: priorityIconName(task.priority), text: task.priority.rawValue, color: priorityColor(task.priority))
                    }

                    // Assigned by
                    HStack(spacing: 5) {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                            .foregroundStyle(Color(.tertiaryLabel))
                        Text("Assigned by \(task.assignedBy)")
                            .font(.footnote)
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                }
                .padding(.vertical, 16)
                .padding(.trailing, 16)
                .padding(.leading, 16)
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(statusColor(task.status).opacity(0.5), lineWidth: 1.0)
        )
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Work Order Card
// ═══════════════════════════════════════════════════════════════

private struct WorkOrderCard: View {
    let workOrder: ScheduledWorkOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 16) {
                    // Header row
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("WO-\(workOrder.id.uuidString.prefix(6).uppercased())")
                                .font(.headline)
                                .foregroundStyle(Color.primary)
                            Text("\(workOrder.vehicleName) · \(workOrder.vehicleNumber)")
                                .font(.footnote)
                                .foregroundStyle(Color(.tertiaryLabel))
                        }
                        Spacer()
                        StatusBadge(
                            text: statusLabel(workOrder.status),
                            color: statusColor(workOrder.status)
                        )
                    }

                    // Labor & Assigned Row
                    HStack(spacing: 16) {
                        InfoPill(icon: "person.fill", text: "By: \(workOrder.assignedBy)")
                        InfoPill(icon: "clock.fill",  text: workOrder.laborHours)
                        InfoPill(icon: "indianrupeesign.circle.fill", text: workOrder.laborCost, color: Color.green)
                    }

                    // Spare parts consumed (if any)
                    if !workOrder.partsUsed.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.brown)
                            Text(workOrder.partsUsed.joined(separator: ", "))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.vertical, 16)
                .padding(.trailing, 16)
                .padding(.leading, 16)
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(statusColor(workOrder.status).opacity(0.5), lineWidth: 1.0)
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
        case .open:       return Color.blue
        case .inProgress: return Color.yellow
        case .completed:  return Color.green
        case .cancelled:  return Color.red
        }
    }

    func priorityColor(_ priority: WorkOrderPriority) -> Color {
        switch priority {
        case .low:      return Color.green
        case .medium:   return Color.blue
        case .high:     return Color.yellow
        case .critical: return Color.red
        }
    }
}

// MARK: - Info Pill
private struct InfoPill: View {
    let icon: String
    let text: String
    var color: Color = Color.secondary

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(color)
            Text(text)
                .font(.caption.weight(.medium))
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
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.brown.opacity(0.08))
                    .frame(width: 120, height: 120)

                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(Color.brown.opacity(0.6))
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
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                Text(message)
                    .font(.body)
                    .foregroundStyle(Color(.tertiaryLabel))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40 + 20)
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
    @State private var laborHours: String = ""
    @State private var laborCost: String = ""
    @State private var estimatedDuration: String = ""

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                    VStack(spacing: 24) {

                        // MARK: Status Banner
                        let currentTask = viewModel.allTasks.first(where: { $0.id == task.id }) ?? task
                        HStack(spacing: 16) {
                            Image(systemName: statusIcon(currentTask.status))
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(statusColor(currentTask.status))
                                .symbolEffect(.pulse, isActive: currentTask.status == .critical)

                            VStack(alignment: .leading, spacing: 3) {
                                  Text(currentTask.vehicleName)
                                      .font(.headline)
                                      .foregroundStyle(Color.primary)
                                  Text(currentTask.vehicleNumber)
                                      .font(.footnote)
                                      .foregroundStyle(Color(.tertiaryLabel))
                            }
                            Spacer()
                            StatusBadge(text: currentTask.status.rawValue, color: statusColor(currentTask.status))
                        }
                        .padding(16)
                        .background(statusColor(currentTask.status).opacity(0.09))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(statusColor(currentTask.status).opacity(0.3), lineWidth: 1)
                        )

                        // MARK: Vehicle Details
                        SheetSection(title: "Task Details") {
                            InfoRow(icon: "car.fill",      label: "Vehicle",   value: "\(currentTask.vehicleName) · \(currentTask.vehicleNumber)")
                            Divider().background(Color(.separator))
                            InfoRow(icon: "wrench.fill",   label: "Type",      value: taskTypeLabel(currentTask.taskType))
                            Divider().background(Color(.separator))
                            InfoRow(icon: "flag.fill",     label: "Priority",  value: currentTask.priority.rawValue, valueColor: priorityColor(currentTask.priority))
                            Divider().background(Color(.separator))
                            InfoRow(icon: "clock.fill",    label: "Time",      value: "\(currentTask.scheduledTime) · \(currentTask.estimatedDuration)")
                            Divider().background(Color(.separator))
                            InfoRow(icon: "person.fill",   label: "Assigned By", value: currentTask.assignedBy)
                        }

                        // MARK: Labor, Financials & Time (Editable)
                        SheetSection(title: "Labor, Financials & Time") {
                            VStack(spacing: 16) {
                                HStack(spacing: 12) {
                                    Image(systemName: "timer")
                                        .foregroundStyle(Color.blue)
                                        .frame(width: 20)
                                    Text("Est. Duration:")
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(Color.primary)
                                    Spacer()
                                    TextField("e.g. 2 hrs", text: $estimatedDuration)
                                        .textFieldStyle(.plain)
                                        .multilineTextAlignment(.trailing)
                                        .font(.body)
                                        .foregroundStyle(Color.secondary)
                                }
                                
                                Divider().background(Color(.separator))
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "clock.fill")
                                        .foregroundStyle(Color.green)
                                        .frame(width: 20)
                                    Text("Labor Hours:")
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(Color.primary)
                                    Spacer()
                                    TextField("e.g. 3", text: $laborHours)
                                        .textFieldStyle(.plain)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.trailing)
                                        .font(.body)
                                        .foregroundStyle(Color.secondary)
                                }
                                
                                Divider().background(Color(.separator))
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "indianrupeesign.circle.fill")
                                        .foregroundStyle(Color.green)
                                        .frame(width: 20)
                                    Text("Labor Cost:")
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(Color.primary)
                                    Spacer()
                                    TextField("e.g. 500", text: $laborCost)
                                        .textFieldStyle(.plain)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.trailing)
                                        .font(.body)
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                        }

                        // MARK: Service Checklist
                        SheetSection(title: "Service Checklist") {
                            let items = currentTask.checklistItems
                            let doneCount = items.filter(\.isChecked).count
                            let totalCount = items.count

                            HStack {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4).fill(Color(.tertiarySystemBackground)).frame(height: 6)
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.green)
                                            .frame(width: totalCount > 0 ? geo.size.width * CGFloat(doneCount) / CGFloat(totalCount) : 0, height: 6)
                                    }
                                }
                                .frame(height: 6)

                                Text("\(doneCount)/\(totalCount)")
                                    .font(.footnote)
                                    .foregroundStyle(Color(.tertiaryLabel))
                                    .frame(width: 36, alignment: .trailing)
                            }

                            Divider().background(Color(.separator))

                            ForEach(items) { item in
                                ChecklistRow(item: item) {
                                    viewModel.toggleChecklist(taskId: currentTask.id, itemId: item.id)
                                }
                                if item.id != items.last?.id {
                                    Divider().background(Color(.separator)).padding(.leading, 32)
                                }
                            }
                        }

                        // MARK: Parts Needed
                        if !currentTask.partsNeeded.isEmpty {
                            SheetSection(title: "Spare Parts Needed") {
                                ForEach(Array(currentTask.partsNeeded.enumerated()), id: \.offset) { idx, part in
                                    HStack(spacing: 16) {
                                        Image(systemName: "gearshape.fill")
                                            .foregroundStyle(Color.brown)
                                            .frame(width: 20)
                                        Text(part)
                                            .font(.body)
                                            .foregroundStyle(Color.primary)
                                        Spacer()
                                    }
                                    if idx < currentTask.partsNeeded.count - 1 {
                                        Divider().background(Color(.separator))
                                    }
                                }
                            }
                        }

                        // MARK: Repair Notes
                        SheetSection(title: "Service Notes") {
                            TextField("Add notes, observations, or findings...", text: $repairNotes, axis: .vertical)
                                .lineLimit(3...6)
                                .font(.body)
                                .foregroundStyle(Color.primary)
                        }

                        // MARK: Previous History
                        SheetSection(title: "Previous History") {
                            HStack(alignment: .top, spacing: 16) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundStyle(Color(.tertiaryLabel))
                                    .frame(width: 20)
                                Text(currentTask.previousNote)
                                    .font(.body)
                                    .foregroundStyle(Color.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        // MARK: AI Recommendation
                        SheetSection(title: "AI Recommendation") {
                            HStack(alignment: .top, spacing: 16) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(Color.yellow)
                                    .font(.system(size: 18, weight: .semibold))
                                Text(currentTask.aiRecommendation)
                                    .font(.body)
                                    .foregroundStyle(Color.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        // MARK: Action Buttons
                        VStack(spacing: 16) {
                            if currentTask.status == .pending || currentTask.status == .delayed {
                                SheetActionButton(title: "Start Task", icon: "play.circle.fill", color: Color.brown) {
                                    viewModel.updateTaskStatus(id: currentTask.id, to: .inProgress)
                                }
                            }
                            if currentTask.status == .inProgress || currentTask.status == .critical {
                                SheetActionButton(title: "Mark as Completed", icon: "checkmark.circle.fill", color: Color.green) {
                                    viewModel.updateTaskStatus(id: currentTask.id, to: .completed)
                                }
                            }
                            if currentTask.status != .completed && currentTask.status != .delayed {
                                SheetActionButton(title: "Report Issue / Delay", icon: "exclamationmark.triangle.fill", color: Color.yellow) {
                                    viewModel.updateTaskStatus(id: currentTask.id, to: .delayed)
                                }
                            }

                            HStack(spacing: 16) {
                                SheetSecondaryButton(title: "Add Photos", icon: "camera")
                                SheetSecondaryButton(title: "Voice Note", icon: "mic.circle")
                            }
                        }
                        .padding(.bottom, 24)
                    }
                    .padding(16)
            }
        }
        .navigationTitle(task.vehicleName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            repairNotes = task.previousNote
            laborHours = task.laborHours ?? ""
            laborCost = task.laborCost ?? ""
            estimatedDuration = task.estimatedDuration
        }
        .onChange(of: laborHours) { _, newValue in
            viewModel.updateTaskLabor(id: task.id, hours: newValue, cost: laborCost)
        }
        .onChange(of: laborCost) { _, newValue in
            viewModel.updateTaskLabor(id: task.id, hours: laborHours, cost: newValue)
        }
        .onChange(of: estimatedDuration) { _, newValue in
            viewModel.updateTaskDuration(id: task.id, duration: newValue)
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Work Order Detail Sheet
// ═══════════════════════════════════════════════════════════════

struct WorkOrderDetailSheet: View {
    let workOrder: ScheduledWorkOrder
    let viewModel: MaintenanceSchedulerViewModel

    private var currentWO: ScheduledWorkOrder {
        viewModel.allWorkOrders.first(where: { $0.id == workOrder.id }) ?? workOrder
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                    VStack(spacing: 24) {

                        // MARK: Status Banner
                        HStack(spacing: 16) {
                            Image(systemName: statusIcon(currentWO.status))
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(statusColor(currentWO.status))

                            VStack(alignment: .leading, spacing: 3) {
                                Text("WO-\(currentWO.id.uuidString.prefix(8).uppercased())")
                                    .font(.headline)
                                    .foregroundStyle(Color.primary)
                                Text("\(currentWO.vehicleName) · \(currentWO.vehicleNumber)")
                                    .font(.footnote)
                                    .foregroundStyle(Color(.tertiaryLabel))
                            }
                            Spacer()
                            StatusBadge(text: statusLabel(currentWO.status), color: statusColor(currentWO.status))
                        }
                        .padding(16)
                        .background(statusColor(currentWO.status).opacity(0.09))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(statusColor(currentWO.status).opacity(0.3), lineWidth: 1)
                        )

                        // MARK: Work Order Details
                        SheetSection(title: "Order Details") {
                            InfoRow(icon: "number",        label: "Order ID",    value: "WO-\(currentWO.id.uuidString.prefix(8).uppercased())")
                            Divider().background(Color(.separator))
                            InfoRow(icon: "car.fill",      label: "Vehicle",     value: "\(currentWO.vehicleName) · \(currentWO.vehicleNumber)")
                            Divider().background(Color(.separator))
                            InfoRow(icon: "flag.fill",     label: "Priority",    value: priorityLabel(currentWO.priority), valueColor: priorityColor(currentWO.priority))
                            Divider().background(Color(.separator))
                            InfoRow(icon: "calendar",      label: "Created At",   value: currentWO.createdAt.formatted(date: .abbreviated, time: .shortened))
                        }

                        // MARK: Reported Problem
                        SheetSection(title: "Reported Problem") {
                            HStack(alignment: .top, spacing: 16) {
                                Image(systemName: "exclamationmark.bubble.fill")
                                    .foregroundStyle(Color.red)
                                    .font(.system(size: 18, weight: .semibold))
                                Text(currentWO.vehicleIssue)
                                    .font(.body)
                                    .foregroundStyle(Color.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        // MARK: Spare Parts Consumed (Read-Only)
                        if !currentWO.partsUsed.isEmpty {
                            SheetSection(title: "Parts Consumed") {
                                ForEach(Array(currentWO.partsUsed.enumerated()), id: \.offset) { idx, part in
                                    HStack(spacing: 16) {
                                        Image(systemName: "gearshape.2.fill")
                                            .foregroundStyle(Color.brown)
                                            .frame(width: 20)
                                        Text(part)
                                            .font(.body)
                                            .foregroundStyle(Color.primary)
                                        Spacer()
                                    }
                                    if idx < currentWO.partsUsed.count - 1 {
                                        Divider().background(Color(.separator))
                                    }
                                }
                            }
                        }

                        // MARK: Notes Section (Read-Only)
                        if !currentWO.notes.isEmpty {
                            SheetSection(title: "Service Notes") {
                                Text(currentWO.notes)
                                    .font(.body)
                                    .foregroundStyle(Color.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .padding(16)
            }
        }
        .navigationTitle("Work Order Details")
        .navigationBarTitleDisplayMode(.inline)
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
        case .open:       return Color.blue
        case .inProgress: return Color.yellow
        case .completed:  return Color.green
        case .cancelled:  return Color.red
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
        case .low:      return Color.green
        case .medium:   return Color.blue
        case .high:     return Color.yellow
        case .critical: return Color.red
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
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: title)
            VStack(spacing: 16) {
                content()
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            )

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
            HStack(spacing: 16) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isChecked ? Color.green : Color(.quaternaryLabel))
                    .font(.system(size: 20))
                    .symbolEffect(.bounce, value: item.isChecked)

                Text(item.title)
                    .font(.body)
                    .foregroundStyle(item.isChecked ? Color(.tertiaryLabel) : Color.primary)
                    .strikethrough(item.isChecked, color: Color(.tertiaryLabel))
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
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.headline)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(color.opacity(0.35), lineWidth: 1)
            )

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
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.body.weight(.medium))
            .foregroundStyle(Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
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
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                Text(label)
                    .font(.footnote)
                    .foregroundStyle(Color(.tertiaryLabel))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Shared Helpers
// ═══════════════════════════════════════════════════════════════

func statusColor(_ status: TaskDisplayStatus) -> Color {
    switch status {
    case .pending:    return Color.blue
    case .inProgress: return Color.yellow
    case .completed:  return Color.green
    case .delayed:    return Color.red
    case .critical:   return Color.red
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
    case .low:       return Color.green
    case .medium:    return Color.blue
    case .high:      return Color.yellow
    case .emergency: return Color.red
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

// ═══════════════════════════════════════════════════════════════
// MARK: - Scale Button Style
// ═══════════════════════════════════════════════════════════════

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Create Task Sheet
// ═══════════════════════════════════════════════════════════════

struct CreateTaskSheet: View {
    let viewModel: MaintenanceSchedulerViewModel
    let initialDate: Date
    let currentUserId: UUID?
    @Environment(\.dismiss) private var dismiss

    @State private var selectedVehicleId: UUID = UUID()
    @State private var selectedTaskType: MaintenanceTaskType = .oilChange
    @State private var selectedPriority: TaskPriority = .medium
    @State private var description: String = ""
    @State private var estimatedDuration: String = "1 hr"
    @State private var laborHours: String = ""
    @State private var laborCost: String = ""
    @State private var scheduledDate: Date = Date()
    
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                Form {
                    Section("Vehicle Details") {
                        Picker("Vehicle", selection: $selectedVehicleId) {
                            Text("Select Vehicle").tag(UUID())
                            ForEach(viewModel.allVehicles) { vehicle in
                                Text("\(vehicle.make ?? "") \(vehicle.model ?? "") (\(vehicle.licensePlate ?? ""))")
                                    .tag(vehicle.id)
                            }
                        }
                    }
                    
                    Section("Task Configuration") {
                        Picker("Task Type", selection: $selectedTaskType) {
                            Text("Oil Change").tag(MaintenanceTaskType.oilChange)
                            Text("Tire Rotation").tag(MaintenanceTaskType.tireRotation)
                            Text("Safety Inspection").tag(MaintenanceTaskType.inspection)
                            Text("Repair").tag(MaintenanceTaskType.repair)
                            Text("Other").tag(MaintenanceTaskType.other)
                        }
                        
                        Picker("Priority", selection: $selectedPriority) {
                            Text("Low").tag(TaskPriority.low)
                            Text("Medium").tag(TaskPriority.medium)
                            Text("High").tag(TaskPriority.high)
                            Text("Emergency").tag(TaskPriority.emergency)
                        }
                        
                        DatePicker("Scheduled Date", selection: $scheduledDate, displayedComponents: [.date, .hourAndMinute])
                    }
                    
                    Section("Labor, Cost & Time") {
                        HStack {
                            Text("Est. Duration")
                            Spacer()
                            TextField("e.g. 2 hrs", text: $estimatedDuration)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Text("Labor Hours")
                            Spacer()
                            TextField("Optional", text: $laborHours)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Text("Labor Cost (₹)")
                            Spacer()
                            TextField("Optional", text: $laborCost)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    Section("Description") {
                        TextField("Describe the service required...", text: $description, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }
            }
            .navigationTitle("Create Maintenance Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.red)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard selectedVehicleId != UUID() else { return }
                        isSaving = true
                        Task {
                            await viewModel.createNewTask(
                                vehicleId: selectedVehicleId,
                                taskType: selectedTaskType,
                                priority: selectedPriority,
                                date: scheduledDate,
                                description: description.isEmpty ? "No description provided." : description,
                                estimatedDuration: estimatedDuration,
                                laborHours: laborHours,
                                laborCost: laborCost,
                                currentUserId: currentUserId
                            )
                            isSaving = false
                            dismiss()
                        }
                    }
                    .bold()
                    .disabled(selectedVehicleId == UUID() || isSaving)
                    .foregroundStyle(selectedVehicleId == UUID() ? Color.gray : Color.brown)
                }
            }
            .onAppear {
                scheduledDate = initialDate
                if let firstVehicle = viewModel.allVehicles.first {
                    selectedVehicleId = firstVehicle.id
                }
            }
        }
    }
}