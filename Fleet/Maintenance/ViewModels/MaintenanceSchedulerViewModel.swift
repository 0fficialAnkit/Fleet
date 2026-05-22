import SwiftUI
import Foundation

// MARK: - Local UI-Layer Enums (Maintenance Scheduler only)

enum TaskPriority: String, CaseIterable {
    case low       = "Low"
    case medium    = "Medium"
    case high      = "High"
    case emergency = "Emergency"
}

enum TaskDisplayStatus: String, CaseIterable {
    case pending    = "Pending"
    case inProgress = "In Progress"
    case completed  = "Completed"
    case delayed    = "Delayed"
    case critical   = "Critical"
}

enum SchedulerTabType: String, CaseIterable {
    case tasks = "Tasks"
    case workOrders = "Work Orders"
}

// MARK: - ChecklistItem

struct ChecklistItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    var isChecked: Bool

    init(title: String, isChecked: Bool = false) {
        self.id = UUID()
        self.title = title
        self.isChecked = isChecked
    }
}

// MARK: - ScheduledTask (UI display model)

struct ScheduledTask: Identifiable, Hashable {
    let id: UUID
    let vehicleNumber: String
    let vehicleName: String
    let taskType: MaintenanceTaskType
    let priority: TaskPriority
    let scheduledTime: String
    let assignedBy: String
    let estimatedDuration: String
    var status: TaskDisplayStatus
    let description: String
    let date: Date
    var checklistItems: [ChecklistItem]
    let partsNeeded: [String]
    let previousNote: String
    let aiRecommendation: String
}

// MARK: - ScheduledWorkOrder (UI display model)

struct ScheduledWorkOrder: Identifiable, Hashable {
    let id: UUID
    let vehicleNumber: String
    let vehicleName: String
    let priority: WorkOrderPriority
    var status: WorkOrderStatus
    let createdAt: Date
    let assignedBy: String
    let laborHours: String
    let laborCost: String
    var notes: String
    var partsUsed: [String]
}

// MARK: - ViewModel

@Observable
final class MaintenanceSchedulerViewModel {

    var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    var selectedTask: ScheduledTask? = nil
    var showTaskDetail: Bool = false
    
    // Unified Navigation & Work Orders State
    var selectedTab: SchedulerTabType = .tasks
    var selectedWorkOrder: ScheduledWorkOrder? = nil
    var showWorkOrderDetail: Bool = false

    // MARK: - Calendar Days
    var calendarDays: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (-7...22).compactMap { cal.date(byAdding: .day, value: $0, to: today) }
    }

    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    func isSelected(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }

    var tasksForSelectedDate: [ScheduledTask] {
        allTasks.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
            .sorted { $0.scheduledTime < $1.scheduledTime }
    }

    var workOrdersForSelectedDate: [ScheduledWorkOrder] {
        allWorkOrders.filter { Calendar.current.isDate($0.createdAt, inSameDayAs: selectedDate) }
            .sorted { $0.createdAt < $1.createdAt }
    }

    var taskCountForDate: [Date: Int] {
        var counts: [Date: Int] = [:]
        for task in allTasks {
            let day = Calendar.current.startOfDay(for: task.date)
            counts[day, default: 0] += 1
        }
        for wo in allWorkOrders {
            let day = Calendar.current.startOfDay(for: wo.createdAt)
            counts[day, default: 0] += 1
        }
        return counts
    }

    // MARK: - Mutations

    func updateTaskStatus(id: UUID, to status: TaskDisplayStatus) {
        if let i = allTasks.firstIndex(where: { $0.id == id }) {
            allTasks[i].status = status
        }
        if selectedTask?.id == id {
            selectedTask?.status = status
        }
    }

    func toggleChecklist(taskId: UUID, itemId: UUID) {
        guard let ti = allTasks.firstIndex(where: { $0.id == taskId }),
              let ci = allTasks[ti].checklistItems.firstIndex(where: { $0.id == itemId }) else { return }
        allTasks[ti].checklistItems[ci].isChecked.toggle()
        if selectedTask?.id == taskId {
            selectedTask = allTasks[ti]
        }
    }

    func updateWorkOrderStatus(id: UUID, to status: WorkOrderStatus) {
        if let i = allWorkOrders.firstIndex(where: { $0.id == id }) {
            allWorkOrders[i].status = status
        }
        if selectedWorkOrder?.id == id {
            selectedWorkOrder?.status = status
        }
    }

    func updateWorkOrderNotes(id: UUID, notes: String) {
        if let i = allWorkOrders.firstIndex(where: { $0.id == id }) {
            allWorkOrders[i].notes = notes
        }
        if selectedWorkOrder?.id == id {
            selectedWorkOrder?.notes = notes
        }
    }

    func addPartToWorkOrder(id: UUID, part: String) {
        if let i = allWorkOrders.firstIndex(where: { $0.id == id }) {
            allWorkOrders[i].partsUsed.append(part)
        }
        if selectedWorkOrder?.id == id {
            selectedWorkOrder?.partsUsed.append(part)
        }
    }

    // MARK: - Mock Data

    var allTasks: [ScheduledTask] = {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        func dt(_ dayOffset: Int, _ hour: Int, _ minute: Int = 0) -> Date {
            let d = cal.date(byAdding: .day, value: dayOffset, to: today)!
            return cal.date(bySettingHour: hour, minute: minute, second: 0, of: d)!
        }

        return [
            // ── TODAY ──────────────────────────────────────────────
            ScheduledTask(
                id: UUID(), vehicleNumber: "MH-12-CX-4490", vehicleName: "Truck #24",
                taskType: .inspection, priority: .high,
                scheduledTime: "09:00 AM", assignedBy: "James Fleet",
                estimatedDuration: "2 hrs", status: .inProgress,
                description: "Full brake system inspection and replacement of front brake pads if worn.",
                date: dt(0, 9),
                checklistItems: [
                    ChecklistItem(title: "Check brake pad thickness", isChecked: true),
                    ChecklistItem(title: "Inspect brake discs for wear", isChecked: true),
                    ChecklistItem(title: "Check brake fluid level", isChecked: false),
                    ChecklistItem(title: "Test brake pedal response", isChecked: false)
                ],
                partsNeeded: ["Brake Pads (Front) × 2", "Brake Fluid DOT4 × 1"],
                previousNote: "Last inspection 3 months ago. Minor wear noted on front pads.",
                aiRecommendation: "High likelihood of pad replacement. Stock front pads before starting."
            ),
            ScheduledTask(
                id: UUID(), vehicleNumber: "MH-14-AB-2234", vehicleName: "Van #08",
                taskType: .oilChange, priority: .medium,
                scheduledTime: "11:30 AM", assignedBy: "James Fleet",
                estimatedDuration: "45 min", status: .pending,
                description: "Scheduled oil change and oil filter replacement.",
                date: dt(0, 11, 30),
                checklistItems: [
                    ChecklistItem(title: "Drain old engine oil"),
                    ChecklistItem(title: "Replace oil filter"),
                    ChecklistItem(title: "Add new oil (5W-30, 5L)"),
                    ChecklistItem(title: "Check for leaks after fill")
                ],
                partsNeeded: ["Engine Oil 5W-30 (5L) × 1", "Oil Filter × 1"],
                previousNote: "Last oil change was 6,000 km ago. Overdue by ~500 km.",
                aiRecommendation: "Routine change — no anomalies expected. Estimated 40 min."
            ),
            ScheduledTask(
                id: UUID(), vehicleNumber: "MH-02-TF-7891", vehicleName: "Bus #03",
                taskType: .tireRotation, priority: .low,
                scheduledTime: "02:00 PM", assignedBy: "Sarah Admin",
                estimatedDuration: "1 hr", status: .pending,
                description: "Rotate all four tyres, check tread depth and tyre pressure.",
                date: dt(0, 14),
                checklistItems: [
                    ChecklistItem(title: "Record current tread depth"),
                    ChecklistItem(title: "Rotate tyres (front → rear)"),
                    ChecklistItem(title: "Inflate to recommended PSI"),
                    ChecklistItem(title: "Check for punctures or cracks")
                ],
                partsNeeded: [],
                previousNote: "Last rotation at 8,000 km. Rear tyres slightly more worn.",
                aiRecommendation: "Consider rear tyre replacement within next 2 rotation cycles."
            ),
            ScheduledTask(
                id: UUID(), vehicleNumber: "MH-12-CX-4490", vehicleName: "Truck #24",
                taskType: .repair, priority: .emergency,
                scheduledTime: "04:30 PM", assignedBy: "James Fleet",
                estimatedDuration: "3 hrs", status: .critical,
                description: "Emergency AC compressor failure. Vehicle grounded until resolved.",
                date: dt(0, 16, 30),
                checklistItems: [
                    ChecklistItem(title: "Diagnose compressor fault code"),
                    ChecklistItem(title: "Check refrigerant levels"),
                    ChecklistItem(title: "Replace compressor unit"),
                    ChecklistItem(title: "Recharge refrigerant (R134a)"),
                    ChecklistItem(title: "Verify cooling output post-repair")
                ],
                partsNeeded: ["AC Compressor × 1", "Refrigerant R134a × 2"],
                previousNote: "Driver reported AC failure mid-route. Unusual noise from engine bay.",
                aiRecommendation: "Compressor bearing likely seized. Order part immediately — 2-3 day lead time if not in stock."
            ),
            // ── YESTERDAY ─────────────────────────────────────────
            ScheduledTask(
                id: UUID(), vehicleNumber: "DL-01-RT-5566", vehicleName: "Pickup #11",
                taskType: .oilChange, priority: .low,
                scheduledTime: "11:00 AM", assignedBy: "James Fleet",
                estimatedDuration: "45 min", status: .completed,
                description: "Routine oil change and engine health check.",
                date: dt(-1, 11),
                checklistItems: [
                    ChecklistItem(title: "Drain old oil", isChecked: true),
                    ChecklistItem(title: "Replace filter", isChecked: true),
                    ChecklistItem(title: "Add new oil", isChecked: true),
                    ChecklistItem(title: "Check for leaks", isChecked: true)
                ],
                partsNeeded: ["Engine Oil × 1", "Oil Filter × 1"],
                previousNote: "Completed without issues.",
                aiRecommendation: "Next oil change due in approximately 5,000 km."
            ),
            ScheduledTask(
                id: UUID(), vehicleNumber: "MH-02-TF-7891", vehicleName: "Bus #03",
                taskType: .inspection, priority: .medium,
                scheduledTime: "09:00 AM", assignedBy: "Sarah Admin",
                estimatedDuration: "1 hr", status: .delayed,
                description: "Pre-route safety inspection — delayed due to part unavailability.",
                date: dt(-1, 9),
                checklistItems: [
                    ChecklistItem(title: "Lights and signals check", isChecked: true),
                    ChecklistItem(title: "Mirror alignment", isChecked: true),
                    ChecklistItem(title: "Fluid levels", isChecked: false),
                    ChecklistItem(title: "Tyre pressure", isChecked: false)
                ],
                partsNeeded: [],
                previousNote: "Inspection paused — technician awaiting coolant delivery.",
                aiRecommendation: "Reschedule completion to earliest available slot today."
            ),
            // ── TOMORROW ──────────────────────────────────────────
            ScheduledTask(
                id: UUID(), vehicleNumber: "DL-01-RT-5566", vehicleName: "Pickup #11",
                taskType: .inspection, priority: .high,
                scheduledTime: "08:00 AM", assignedBy: "James Fleet",
                estimatedDuration: "1.5 hrs", status: .pending,
                description: "Pre-trip safety inspection before long-haul assignment.",
                date: dt(1, 8),
                checklistItems: [
                    ChecklistItem(title: "Lights and signals check"),
                    ChecklistItem(title: "Mirror alignment"),
                    ChecklistItem(title: "Fluid levels check"),
                    ChecklistItem(title: "Tyre pressure verification")
                ],
                partsNeeded: [],
                previousNote: "Vehicle assigned for 450 km intercity route.",
                aiRecommendation: "All systems nominal based on last log. Quick check should suffice."
            ),
            ScheduledTask(
                id: UUID(), vehicleNumber: "MH-14-AB-2234", vehicleName: "Van #08",
                taskType: .other, priority: .medium,
                scheduledTime: "10:00 AM", assignedBy: "Sarah Admin",
                estimatedDuration: "30 min", status: .pending,
                description: "Windshield wiper replacement and washer fluid top-up.",
                date: dt(1, 10),
                checklistItems: [
                    ChecklistItem(title: "Remove old wiper blades"),
                    ChecklistItem(title: "Fit new blades"),
                    ChecklistItem(title: "Top up washer fluid")
                ],
                partsNeeded: ["Windshield Wipers × 2", "Washer Fluid × 1"],
                previousNote: "Driver reported poor visibility during rain.",
                aiRecommendation: "Standard replacement. No complex diagnosis needed."
            ),
            // ── DAY AFTER TOMORROW ───────────────────────────────
            ScheduledTask(
                id: UUID(), vehicleNumber: "MH-02-TF-7891", vehicleName: "Bus #03",
                taskType: .repair, priority: .high,
                scheduledTime: "09:30 AM", assignedBy: "James Fleet",
                estimatedDuration: "4 hrs", status: .pending,
                description: "Transmission fluid flush and filter replacement.",
                date: dt(2, 9, 30),
                checklistItems: [
                    ChecklistItem(title: "Drain transmission fluid"),
                    ChecklistItem(title: "Replace transmission filter"),
                    ChecklistItem(title: "Refill with ATF fluid"),
                    ChecklistItem(title: "Road test post-service")
                ],
                partsNeeded: ["ATF Fluid (4L) × 2", "Transmission Filter × 1"],
                previousNote: "Slight delay in gear engagement reported by driver.",
                aiRecommendation: "Fluid degradation suspected. Flush before it causes downstream damage."
            )
        ]
    }()

    var allWorkOrders: [ScheduledWorkOrder] = {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        func dt(_ dayOffset: Int, _ hour: Int, _ minute: Int = 0) -> Date {
            let d = cal.date(byAdding: .day, value: dayOffset, to: today)!
            return cal.date(bySettingHour: hour, minute: minute, second: 0, of: d)!
        }

        return [
            // ── TODAY ──────────────────────────────────────────────
            ScheduledWorkOrder(
                id: UUID(), vehicleNumber: "MH-12-CX-4490", vehicleName: "Truck #24",
                priority: .critical, status: .inProgress,
                createdAt: dt(0, 9, 30), assignedBy: "Sarah Admin",
                laborHours: "3.5 hrs", laborCost: "$210",
                notes: "Technician in progress of replacing compressor and pads.",
                partsUsed: ["Brake Pads (Front) × 2", "Brake Fluid DOT4 × 1"]
            ),
            ScheduledWorkOrder(
                id: UUID(), vehicleNumber: "MH-14-AB-2234", vehicleName: "Van #08",
                priority: .medium, status: .open,
                createdAt: dt(0, 13), assignedBy: "James Fleet",
                laborHours: "1.0 hr", laborCost: "$60",
                notes: "Pending assignment to secondary bay.",
                partsUsed: ["Engine Oil 5W-30 (5L) × 1", "Oil Filter × 1"]
            ),
            // ── YESTERDAY ─────────────────────────────────────────
            ScheduledWorkOrder(
                id: UUID(), vehicleNumber: "DL-01-RT-5566", vehicleName: "Pickup #11",
                priority: .low, status: .completed,
                createdAt: dt(-1, 10), assignedBy: "Sarah Admin",
                laborHours: "0.5 hrs", laborCost: "$30",
                notes: "Topped up coolant and verified all levels.",
                partsUsed: ["Engine Coolant × 1"]
            ),
            ScheduledWorkOrder(
                id: UUID(), vehicleNumber: "MH-02-TF-7891", vehicleName: "Bus #03",
                priority: .high, status: .cancelled,
                createdAt: dt(-1, 14), assignedBy: "James Fleet",
                laborHours: "0 hrs", laborCost: "$0",
                notes: "Trip cancelled. Postponed maintenance to next week.",
                partsUsed: []
            ),
            // ── TOMORROW ──────────────────────────────────────────
            ScheduledWorkOrder(
                id: UUID(), vehicleNumber: "DL-01-RT-5566", vehicleName: "Pickup #11",
                priority: .high, status: .open,
                createdAt: dt(1, 8, 30), assignedBy: "James Fleet",
                laborHours: "2.0 hrs", laborCost: "$120",
                notes: "Spark plug maintenance scheduled for early morning routing.",
                partsUsed: ["Spark Plugs × 4"]
            )
        ]
    }()
}
