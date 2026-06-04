import Foundation
import Supabase

enum IssueReportService {

    // MARK: - Fetch all issue reports (for manager)

    static func fetchAllIssueReports() async throws -> [IssueReportRecord] {
        try await supabase
            .from("issue_reports")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    // MARK: - Fetch issue reports by driver

    static func fetchIssueReportsForDriver(reportedBy: UUID) async throws -> [IssueReportRecord] {
        try await supabase
            .from("issue_reports")
            .select()
            .eq("reported_by", value: reportedBy)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    // MARK: - Fetch issue reports assigned to user

    static func fetchIssueReportsAssignedTo(userId: UUID) async throws -> [IssueReportRecord] {
        try await supabase
            .from("issue_reports")
            .select()
            .eq("assigned_to", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    // MARK: - Create issue report

    static func createIssueReport(_ report: IssueReportRecord) async throws {
        try await supabase
            .from("issue_reports")
            .insert(report)
            .execute()
    }

    // MARK: - Update issue report (assign + status)

    static func updateIssueReport(id: UUID, assignedTo: UUID?, status: String) async throws {
        struct ReportUpdate: Encodable {
            let assigned_to: UUID?
            let status: String
        }
        try await supabase
            .from("issue_reports")
            .update(ReportUpdate(assigned_to: assignedTo, status: status))
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Resolve with full maintenance details

    /// Called when maintenance marks the work complete. Writes the full breakdown
    /// so fleet managers can see every detail in the issue report.
    static func resolveWithDetails(
        id: UUID,
        assignedTo: UUID?,
        notes: String,
        laborCost: String,
        extraCost: String,
        partsCost: String,
        totalCost: String,
        parts: String,
        resolvedAt: Date = Date()
    ) async throws {
        struct ResolutionUpdate: Encodable {
            let status: String
            let assigned_to: UUID?
            let resolved_at: Date
            let maintenance_notes: String
            let labor_cost: String
            let extra_cost: String
            let parts_cost: String
            let total_cost: String
            let parts_used: String
        }
        try await supabase
            .from("issue_reports")
            .update(ResolutionUpdate(
                status: "resolved",
                assigned_to: assignedTo,
                resolved_at: resolvedAt,
                maintenance_notes: notes,
                labor_cost: laborCost,
                extra_cost: extraCost,
                parts_cost: partsCost,
                total_cost: totalCost,
                parts_used: parts
            ))
            .eq("id", value: id)
            .execute()
        print("[IssueReportService] resolveWithDetails(\(id.uuidString.prefix(6))): OK")
    }

    // MARK: - Delete report (fleet manager only)

    static func deleteReport(id: UUID) async throws {
        do {
            try await supabase
                .from("issue_reports")
                .delete()
                .eq("id", value: id)
                .execute()
            print("[IssueReportService] deleteReport(\(id.uuidString.prefix(6))): OK")
        } catch {
            print("[IssueReportService] deleteReport ERROR: \(error)")
            throw error
        }
    }

    /// Marks work as started (status → in_progress) and records the start time.
    static func markInProgress(id: UUID, assignedTo: UUID?, startedAt: Date = Date()) async throws {
        struct InProgressUpdate: Encodable {
            let status: String
            let assigned_to: UUID?
            let work_started_at: Date
        }
        try await supabase
            .from("issue_reports")
            .update(InProgressUpdate(status: "in_progress", assigned_to: assignedTo, work_started_at: startedAt))
            .eq("id", value: id)
            .execute()
        print("[IssueReportService] markInProgress(\(id.uuidString.prefix(6))): OK")
    }

}