import SwiftUI

// MARK: - Issue Report Status
enum IssueReportStatus: String, CaseIterable, Identifiable {
    case open       = "Open"
    case assigned   = "Assigned"
    case inProgress = "In Progress"
    case resolved   = "Resolved"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .open:       return themeModel.danger
        case .assigned:   return themeModel.warning
        case .inProgress: return themeModel.info
        case .resolved:   return themeModel.success
        }
    }

    var icon: String {
        switch self {
        case .open:       return "exclamationmark.circle.fill"
        case .assigned:   return "person.fill.checkmark"
        case .inProgress: return "wrench.and.screwdriver.fill"
        case .resolved:   return "checkmark.circle.fill"
        }
    }
}

// MARK: - Issue Report Model
struct IssueReport: Identifiable {
    let id: UUID
    let vehicleId: UUID
    let vehicleName: String
    let licensePlate: String
    let driverName: String
    let issueCategory: String
    let severity: DefectSeverity
    let description: String
    let submittedAt: Date
    var assignedTo: UUID?
    var status: IssueReportStatus
}

// MARK: - Status History Entry
struct StatusHistoryEntry: Identifiable {
    let id = UUID()
    let status: IssueReportStatus
    let timestamp: Date
    let note: String
}

// MARK: - Reports ViewModel
@Observable
final class ReportsViewModel {

    // All maintenance staff
    private let allUsers: [User] = MockData.users
    private let allRoles: [Role] = MockData.roles
    private let allVehicles: [Vehicle] = MockData.vehicles

    // In-memory issue reports built from DefectReport mock data
    var reports: [IssueReport]

    init() {
        let users    = MockData.users
        let _ = MockData.roles
        let vehicles = MockData.vehicles
        let inspections = MockData.vehicleInspections
        let defects  = MockData.defectReports

        // Resolve role IDs for maintenance
        func userName(_ id: UUID?) -> String {
            guard let id else { return "Unknown" }
            return users.first { $0.id == id }?.fullName ?? "Unknown"
        }

        func vehicleFor(_ inspectionId: UUID) -> Vehicle? {
            guard let insp = inspections.first(where: { $0.id == inspectionId }) else { return nil }
            return vehicles.first { $0.id == insp.vehicleId }
        }

        self.reports = defects.enumerated().map { idx, defect in
            let vehicle = vehicleFor(defect.inspectionId)
            let make    = vehicle?.make ?? "Vehicle"
            let model   = vehicle?.model ?? ""
            let plate   = vehicle?.licensePlate ?? "—"
            let driver  = userName(defect.reportedBy)

            // Assign category from index cycling through IssueCategory
            let categories = ["Engine Problem", "Tire Issue", "Brake Issue",
                              "Electrical Fault", "Fuel Leak", "Body Damage", "Other"]
            let category = categories[idx % categories.count]

            // Derive initial status from defect status
            let status: IssueReportStatus
            switch defect.status {
            case .open:     status = .open
            case .resolved: status = .resolved
            case .closed:   status = .resolved
            case .none:     status = .open
            }

            return IssueReport(
                id: defect.id,
                vehicleId: vehicle?.id ?? UUID(),
                vehicleName: "\(make) \(model)",
                licensePlate: plate,
                driverName: driver,
                issueCategory: category,
                severity: defect.severity ?? .medium,
                description: defect.description ?? "No description provided.",
                submittedAt: Calendar.current.date(byAdding: .hour, value: -(idx + 1) * 4, to: Date())!,
                assignedTo: nil,
                status: status
            )
        }
    }

    // MARK: - Computed Counts
    var openCount: Int       { reports.filter { $0.status == .open }.count }
    var assignedCount: Int   { reports.filter { $0.status == .assigned || $0.status == .inProgress }.count }
    var resolvedCount: Int   { reports.filter { $0.status == .resolved }.count }

    // MARK: - Maintenance Staff
    var maintenanceStaff: [User] {
        allUsers.filter { user in
            let role = allRoles.first { $0.id == user.roleId }
            return role?.roleName.lowercased() == "maintenance"
        }
    }

    func staffName(_ id: UUID?) -> String {
        guard let id else { return "Unassigned" }
        return allUsers.first { $0.id == id }?.fullName ?? "Unknown"
    }

    // MARK: - Mutating Actions
    func update(reportId: UUID, assignedTo: UUID?, status: IssueReportStatus) {
        guard let idx = reports.firstIndex(where: { $0.id == reportId }) else { return }
        reports[idx].assignedTo = assignedTo
        reports[idx].status = status
    }

    // MARK: - Severity helpers
    func severityColor(_ s: DefectSeverity) -> Color {
        switch s {
        case .low:      return themeModel.success
        case .medium:   return themeModel.warning
        case .high:     return Color.orange
        case .critical: return themeModel.danger
        }
    }
}
