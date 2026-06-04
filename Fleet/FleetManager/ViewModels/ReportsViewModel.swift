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
        case .open:       return Color.red
        case .assigned:   return Color.orange
        case .inProgress: return Color.blue
        case .resolved:   return Color.green
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

    var dbValue: String {
        switch self {
        case .open:       return "open"
        case .assigned:   return "assigned"
        case .inProgress: return "in_progress"
        case .resolved:   return "resolved"
        }
    }

    static func from(dbValue: String) -> IssueReportStatus {
        switch dbValue {
        case "open":        return .open
        case "assigned":    return .assigned
        case "in_progress": return .inProgress
        case "resolved":    return .resolved
        default:            return .open
        }
    }
}

// MARK: - Issue Report Model (view model for display)
struct IssueReport: Identifiable {
    let id: UUID
    let vehicleId: UUID
    let reportedBy: UUID
    let vehicleName: String
    let licensePlate: String
    let driverName: String
    let driverLicenseNumber: String?
    let issueCategory: String
    let severity: DefectSeverity
    let description: String
    let submittedAt: Date
    var assignedTo: UUID?
    var status: IssueReportStatus
    let issuePhotoUrl: String?
    /// When the report was assigned to maintenance staff (from the linked MaintenanceTask.scheduledDate)
    var assignedAt: Date?
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

    private(set) var profiles: [Profile] = []
    private(set) var allVehicles: [Vehicle] = []
    private(set) var allTrips: [Trip] = []
    var maintenanceTasks: [MaintenanceTask] = []

    var reports: [IssueReport] = []
    var isLoading = false
    var errorMessage: String?
    /// Set once on login from AuthViewModel.currentUserId
    var adminId: UUID?

    func loadData() async {
        isLoading = true
        errorMessage = nil

        async let p  = try? ProfileService.fetchAllProfiles(managerId: adminId)
        async let v  = try? VehicleService.fetchAllVehicles(adminId: adminId)
        async let ir = try? IssueReportService.fetchAllIssueReports()
        async let t  = try? MaintenanceTaskService.fetchAllTasks()
        async let tr = try? TripService.fetchAllTrips(adminId: adminId)

        profiles         = (await p) ?? []
        allVehicles      = (await v) ?? []
        let issueRecords = (await ir) ?? []
        maintenanceTasks = (await t) ?? []
        allTrips         = (await tr) ?? []

            // Build display reports from issue_reports table
            self.reports = issueRecords.map { record in
                let vehicle       = allVehicles.first { $0.id == record.vehicleId }
                let make          = vehicle?.make  ?? "Vehicle"
                let model         = vehicle?.model ?? ""
                let plate         = vehicle?.licensePlate ?? "—"
                let driver        = profileName(record.reportedBy)
                let driverLicense = profiles.first { $0.id == record.reportedBy }?.licenseNumber

                let severity: DefectSeverity
                switch record.severity {
                case "low":      severity = .low
                case "high":     severity = .high
                case "critical": severity = .critical
                default:         severity = .medium
                }

                // Find the most recent MaintenanceTask for this vehicle to get the assignment timestamp.
                // Match on vehicleId; if report has an assignee, prefer tasks assigned to that person.
                let tasksForVehicle = maintenanceTasks
                    .filter { $0.vehicleId == record.vehicleId }
                    .sorted { ($0.scheduledDate ?? .distantPast) > ($1.scheduledDate ?? .distantPast) }
                let linkedTask = tasksForVehicle.first { $0.assignedTo == record.assignedTo }
                    ?? tasksForVehicle.first
                let assignedAt = linkedTask?.scheduledDate

                return IssueReport(
                    id: record.id,
                    vehicleId: record.vehicleId,
                    reportedBy: record.reportedBy,
                    vehicleName: "\(make) \(model)",
                    licensePlate: plate,
                    driverName: driver,
                    driverLicenseNumber: driverLicense,
                    issueCategory: record.category,
                    severity: severity,
                    description: record.description ?? "No description provided.",
                    submittedAt: record.createdAt ?? Date(),
                    assignedTo: record.assignedTo,
                    status: IssueReportStatus.from(dbValue: record.status),
                    issuePhotoUrl: record.issuePhoto,
                    assignedAt: assignedAt
                )
            }
        isLoading = false
    }

    func setupRealtime() {
        let rt = RealtimeManager.shared
        rt.addDefectReportsChangeHandler { [weak self] in
            Task { await self?.loadData() }
        }
        rt.addIssueReportsChangeHandler { [weak self] in
            Task { await self?.loadData() }
        }
        rt.addMaintenanceTasksChangeHandler { [weak self] in
            Task { await self?.loadData() }
        }
    }

    // MARK: - Lookup Helpers

    private func profileName(_ id: UUID?) -> String {
        guard let id else { return "Unknown" }
        return profiles.first { $0.id == id }?.fullName ?? "Unknown"
    }

    func vehicle(for id: UUID) -> Vehicle? {
        allVehicles.first { $0.id == id }
    }

    func profile(for id: UUID?) -> Profile? {
        guard let id else { return nil }
        return profiles.first { $0.id == id }
    }

    /// Most recent trip for a given vehicle (by end/start time descending).
    func lastTrip(for vehicleId: UUID) -> Trip? {
        allTrips
            .filter { $0.vehicleId == vehicleId }
            .sorted {
                ($0.endTime ?? $0.startTime ?? .distantPast) >
                ($1.endTime ?? $1.startTime ?? .distantPast)
            }
            .first
    }

    // MARK: - Computed Counts
    var openCount: Int     { reports.filter { $0.status == .open }.count }
    var assignedCount: Int { reports.filter { $0.status == .assigned || $0.status == .inProgress }.count }
    var resolvedCount: Int { reports.filter { $0.status == .resolved }.count }

    // MARK: - Maintenance Staff
    var maintenanceStaff: [Profile] {
        profiles.filter { $0.role == "maintenance" }
    }

    func staffName(_ id: UUID?) -> String {
        guard let id else { return "Unassigned" }
        return profiles.first { $0.id == id }?.fullName ?? "Unknown"
    }

    func staffWorkloadStatus(_ staffId: UUID) -> String {
        let activeTasks = maintenanceTasks.filter { $0.assignedTo == staffId && $0.status == .inProgress }
        if let activeTask = activeTasks.first,
           let vehicle = allVehicles.first(where: { $0.id == activeTask.vehicleId }) {
            return "Working on \(vehicle.make ?? "") \(vehicle.model ?? "")"
        } else if !activeTasks.isEmpty {
            return "Working on vehicle"
        }
        let pendingTasks = maintenanceTasks.filter { $0.assignedTo == staffId && $0.status == .pending }
        if !pendingTasks.isEmpty { return "Assigned (Pending)" }
        return "Available"
    }

    func staffWorkloadColor(_ staffId: UUID) -> Color {
        let activeTasks = maintenanceTasks.filter { $0.assignedTo == staffId && $0.status == .inProgress }
        if !activeTasks.isEmpty { return Color.blue }
        let pendingTasks = maintenanceTasks.filter { $0.assignedTo == staffId && $0.status == .pending }
        if !pendingTasks.isEmpty { return Color.orange }
        return Color.green
    }

    // MARK: - Mutating Actions (persists to Supabase)
    func update(reportId: UUID, assignedTo: UUID?, status: IssueReportStatus, assignedAt: Date? = nil) {
        guard let idx = reports.firstIndex(where: { $0.id == reportId }) else { return }
        reports[idx].assignedTo = assignedTo
        reports[idx].status     = status
        // Set assignment timestamp in-memory so the card shows it immediately
        if let t = assignedAt {
            reports[idx].assignedAt = t
        }

        Task {
            do {
                try await IssueReportService.updateIssueReport(
                    id: reportId,
                    assignedTo: assignedTo,
                    status: status.dbValue
                )
                if let staffId = assignedTo {
                    let notification = Notification(
                        id: UUID(),
                        userId: staffId,
                        title: "Issue Assigned",
                        message: "A new issue report has been assigned to you: \(reports[idx].issueCategory) on \(reports[idx].vehicleName)",
                        type: .maintenance,
                        isRead: false,
                        createdAt: Date()
                    )
                    try? await NotificationService.createNotification(notification)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Severity Color
    func severityColor(_ s: DefectSeverity) -> Color {
        switch s {
        case .low:      return Color.green
        case .medium:   return Color.yellow
        case .high:     return Color.orange
        case .critical: return Color.red
        }
    }
}
