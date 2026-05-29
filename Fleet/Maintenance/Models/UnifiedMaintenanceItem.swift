import Foundation

enum UnifiedMaintenanceItem: Identifiable, Hashable {
    case workOrder(WorkOrder)
    case issueReport(IssueReportRecord)

    var id: UUID {
        switch self {
        case .workOrder(let wo): return wo.id
        case .issueReport(let ir): return ir.id
        }
    }

    var vehicleId: UUID {
        switch self {
        case .workOrder(let wo): return wo.vehicleId
        case .issueReport(let ir): return ir.vehicleId
        }
    }

    var title: String {
        switch self {
        case .workOrder:
            return "Work Order"
        case .issueReport(let ir):
            return ir.category
        }
    }

    var subtitle: String {
        switch self {
        case .workOrder(let wo):
            return "WO-\(wo.id.uuidString.prefix(6).uppercased())"
        case .issueReport(let ir):
            return ir.description ?? "Issue Report"
        }
    }

    var unifiedPriority: WorkOrderPriority? {
        switch self {
        case .workOrder(let wo):
            return wo.priority
        case .issueReport(let ir):
            switch ir.severity.lowercased() {
            case "critical": return .critical
            case "high": return .high
            case "medium": return .medium
            case "low": return .low
            default: return nil
            }
        }
    }

    var unifiedStatus: WorkOrderStatus? {
        switch self {
        case .workOrder(let wo):
            return wo.status
        case .issueReport(let ir):
            switch ir.status.lowercased() {
            case "open", "assigned": return .open
            case "in_progress": return .inProgress
            case "resolved", "closed": return .completed
            case "cancelled": return .cancelled
            default: return nil
            }
        }
    }

    var createdAt: Date? {
        switch self {
        case .workOrder(let wo): return wo.createdAt
        case .issueReport(let ir): return ir.createdAt
        }
    }
}

import SwiftUI

enum MaintenanceDestination: Hashable {
    case workOrderDetail(WorkOrder)
    case issueReportDetail(IssueReportRecord)
    case workOrderList(filter: WorkOrderStatus?, assignedTo: UUID?, priority: WorkOrderPriority?)
    case taskDetail(ScheduledTask)
}

struct UpcomingDisplayItem: Identifiable, Hashable {
    let id: UUID
    let priorityLabel: String?
    let priorityColor: Color?
    let referenceId: String
    let assignmentTag: String
    let vehicleName: String
    let taskDescription: String
    let estimatedDuration: String
    let location: String
    let actionButtonTitle: String
    let actionButtonIcon: String
    let destination: MaintenanceDestination?
    let isTask: Bool
}