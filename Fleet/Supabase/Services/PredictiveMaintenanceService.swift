// PredictiveMaintenanceService.swift
// Fleet
//
// Two-rule on-device engine:
//   Rule 1 — Total trip distance exceeds 10,000 km.
//   Rule 2 — 3 or more open issue reports whose category mentions
//             "engine", "fuel", or "leak" (case-insensitive).
//
// Vehicles already in `.maintenance` status are excluded — they are
// already counted in the "Service" stat and handled by MaintenanceView.

import Foundation

enum PredictiveMaintenanceService {

    // Categories that trigger Rule 2
    private static let watchedKeywords = ["engine", "fuel", "leak"]

    // MARK: - Main analysis entry point

    static func analyze(
        vehicles: [Vehicle],
        trips: [Trip],
        inspections: [VehicleInspection],
        issueReports: [IssueReportRecord],
        maintenanceHistory: [MaintenanceHistory]
    ) -> [PredictiveMaintenanceAlert] {

        var alerts: [PredictiveMaintenanceAlert] = []

        for vehicle in vehicles {

            // Skip vehicles already assigned to the service bay
            guard vehicle.status != .maintenance else { continue }

            var signals: [PredictiveMaintenanceAlert.TriggerSignal] = []

            // ── Rule 1: Distance > 10,000 km ─────────────────────────
            let totalKM = trips
                .filter { $0.vehicleId == vehicle.id && $0.status == .completed }
                .compactMap(\.distance)
                .reduce(0, +)

            if totalKM >= 10_000 {
                let pct = totalKM / 10_000.0
                signals.append(.distanceThreshold(pct: pct))
            }

            // ── Rule 2: 3+ open engine / fuel / leak reports ──────────
            let criticalReports = issueReports.filter { report in
                guard report.vehicleId == vehicle.id else { return false }
                guard report.status != "resolved" && report.status != "closed" else { return false }
                let category = report.category.lowercased()
                return watchedKeywords.contains(where: { category.contains($0) })
            }

            if criticalReports.count >= 3 {
                signals.append(.openCriticalDefect(count: criticalReports.count))
            }

            guard !signals.isEmpty else { continue }

            // ── Build alert ───────────────────────────────────────────
            let severity: PredictiveMaintenanceAlert.AlertSeverity =
                signals.contains(where: {
                    if case .openCriticalDefect = $0 { return true }
                    if case .distanceThreshold(let p) = $0, p >= 1.5 { return true }
                    return false
                }) ? .critical : .warning

            let (reason, recommendation) = buildMessage(
                signals: signals,
                vehicle: vehicle,
                totalKM: totalKM,
                reportCount: criticalReports.count
            )

            alerts.append(PredictiveMaintenanceAlert(
                id: vehicle.id,
                vehicle: vehicle,
                reason: reason,
                recommendation: recommendation,
                severity: severity,
                triggerSignals: signals
            ))
        }

        return alerts.sorted {
            if $0.severity != $1.severity { return $0.severity > $1.severity }
            let n0 = "\($0.vehicle.make ?? "") \($0.vehicle.model ?? "")"
            let n1 = "\($1.vehicle.make ?? "") \($1.vehicle.model ?? "")"
            return n0 < n1
        }
    }

    // MARK: - Human-readable message

    private static func buildMessage(
        signals: [PredictiveMaintenanceAlert.TriggerSignal],
        vehicle: Vehicle,
        totalKM: Double,
        reportCount: Int
    ) -> (reason: String, recommendation: String) {

        // Rule 2 takes priority (more urgent)
        if signals.contains(where: { if case .openCriticalDefect = $0 { return true }; return false }) {
            return (
                "\(reportCount) open engine / fuel / leak report\(reportCount > 1 ? "s" : "")",
                "Inspect the vehicle immediately and send it to the service bay before the next trip."
            )
        }

        // Rule 1
        return (
            String(format: "%.0f km total distance reached", totalKM),
            "Schedule a full service — the vehicle has hit the 10,000 km maintenance threshold."
        )
    }
}
