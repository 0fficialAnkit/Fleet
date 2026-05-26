import Foundation
import Supabase

enum DefectReportService {

    static func fetchAllDefectReports() async throws -> [DefectReport] {
        try await supabase
            .from("defect_reports")
            .select()
            .execute()
            .value
    }

    static func fetchDefectReportsForInspection(inspectionId: UUID) async throws -> [DefectReport] {
        try await supabase
            .from("defect_reports")
            .select()
            .eq("inspection_id", value: inspectionId)
            .execute()
            .value
    }

    static func createDefectReport(_ report: DefectReport) async throws {
        try await supabase
            .from("defect_reports")
            .insert(report)
            .execute()
    }

    static func updateDefectReport(_ report: DefectReport) async throws {
        try await supabase
            .from("defect_reports")
            .update(report)
            .eq("id", value: report.id)
            .execute()
    }

    static func updateDefectStatus(id: UUID, status: DefectStatus) async throws {
        struct StatusUpdate: Encodable {
            let status: DefectStatus
        }
        try await supabase
            .from("defect_reports")
            .update(StatusUpdate(status: status))
            .eq("id", value: id)
            .execute()
    }
}