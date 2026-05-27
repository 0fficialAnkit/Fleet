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
}