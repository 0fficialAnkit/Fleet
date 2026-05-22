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
@MainActor
@Observable
final class ReportsViewModel {

    private(set) var allUsers: [User] = []
    private(set) var allRoles: [Role] = []
    private(set) var allVehicles: [Vehicle] = []

    var reports: [IssueReport] = []
    var isLoading = false
    var errorMessage: String?

    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let u = UserService.fetchAllUsers()
            async let r = UserService.fetchAllRoles()
            async let v = VehicleService.fetchAllVehicles()
            async let insp = InspectionService.fetchAllInspections()
            async let defects = DefectReportService.fetchAllDefectReports()

            allUsers = try await u
            allRoles = try await r
            allVehicles = try await v
            let inspections = try await insp
            let defectReports = try await defects

            // Build issue reports from defect reports
            self.reports = defectReports.enumerated().map { idx, defect in
                let vehicle = vehicleForInspection(defect.inspectionId, inspections: inspections)
                let make = vehicle?.make ?? "Vehicle"
                let model = vehicle?.model ?? ""
                let plate = vehicle?.licensePlate ?? "—"
                let driver = userName(defect.reportedBy)

                let categories = ["Engine Problem", "Tire Issue", "Brake Issue",
                                  "Electrical Fault", "Fuel Leak", "Body Damage", "Other"]
                let category = categories[idx % categories.count]

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
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func setupRealtime() {
        RealtimeManager.shared.onDefectReportsChange = { [weak self] in
            Task { await self?.loadData() }
        }
    }

    // MARK: - Helpers

    private func userName(_ id: UUID?) -> String {
        guard let id else { return "Unknown" }
        return allUsers.first { $0.id == id }?.fullName ?? "Unknown"
    }

    private func vehicleForInspection(_ inspectionId: UUID, inspections: [VehicleInspection]) -> Vehicle? {
        guard let insp = inspections.first(where: { $0.id == inspectionId }) else { return nil }
        return allVehicles.first { $0.id == insp.vehicleId }
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
