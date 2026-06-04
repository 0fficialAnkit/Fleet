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

            // ── Rule 1: Distance > 200 km ─────────────────────────
            let totalKM = trips
                .filter { $0.vehicleId == vehicle.id && $0.status == .completed }
                .compactMap(\.distance)
                .reduce(0, +)

            if totalKM >= 200 {
                let pct = totalKM / 200.0
                signals.append(.distanceThreshold(pct: pct))
            }

            // ── Rule 2: 2+ open engine / fuel / leak reports ──────────
            let criticalReports = issueReports.filter { report in
                guard report.vehicleId == vehicle.id else { return false }
                guard report.status != "resolved" && report.status != "closed" else { return false }
                let category = report.category.lowercased()
                return watchedKeywords.contains(where: { category.contains($0) })
            }

            if criticalReports.count >= 2 {
                signals.append(.openCriticalDefect(count: criticalReports.count))
            }

            // ── Rule 3: AI Overdue Service suggestion (over 2 days since last service) ──
            let vehicleHistory = maintenanceHistory
                .filter { $0.vehicleId == vehicle.id && $0.completedAt != nil }
                .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
            if let lastMh = vehicleHistory.first, let completedAt = lastMh.completedAt {
                let days = Calendar.current.dateComponents([.day], from: completedAt, to: Date()).day ?? 0
                if days >= 2 {
                    signals.append(.overdueService(daysSince: days))
                }
            }

            // ── Rule 4: AI Performance/Reliability warning (history of multiple issues + high usage) ──
            let totalIssues = issueReports.filter { $0.vehicleId == vehicle.id }.count
            let totalTrips = trips.filter { $0.vehicleId == vehicle.id && $0.status == .completed }.count
            if totalIssues >= 2 && totalKM >= 200 {
                signals.append(.usageSpike(recentTrips: totalTrips, avgTrips: Double(totalIssues)))
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

        // Rule 3: Overdue Service
        if let overdueSignal = signals.first(where: { if case .overdueService = $0 { return true }; return false }) {
            if case .overdueService(let days) = overdueSignal {
                return (
                    "AI: Last maintenance was \(days) days ago (exceeds 2-day recommendation)",
                    "Perform routine inspection. AI analysis of performance history suggests preventative tune-up to maintain optimal efficiency."
                )
            }
        }

        // Rule 4: Usage Spike / Reliability history
        if let usageSignal = signals.first(where: { if case .usageSpike = $0 { return true }; return false }) {
            if case .usageSpike(let recentTrips, let issueCount) = usageSignal {
                return (
                    String(format: "AI: High wear-and-tear detected (%.0f km, %d trips, %d history issues)", totalKM, recentTrips, Int(issueCount)),
                    "Schedule inspection of brake pads, suspension, and tires based on performance history and recent mileage."
                )
            }
        }

        // Rule 1
        return (
            String(format: "%.0f km total distance reached", totalKM),
            "Schedule a full service — the vehicle has hit the 200 km maintenance threshold."
        )
    }

    // MARK: - Check and Trigger Preventive Alerts (50 km logic)

    static func checkAndTriggerPreventiveAlerts(
        vehicles: [Vehicle],
        trips: [Trip],
        maintenanceHistory: [MaintenanceHistory],
        issueReports: [IssueReportRecord],
        adminId: UUID?
    ) async {
        for vehicle in vehicles {
            // Find completed maintenance date
            let vehicleHistory = maintenanceHistory
                .filter { $0.vehicleId == vehicle.id && $0.completedAt != nil }
                .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
            let lastMaintenanceDate = vehicleHistory.first?.completedAt

            // Calculate distance since last maintenance
            let tripsSince = trips.filter { trip in
                guard trip.vehicleId == vehicle.id && trip.status == .completed else { return false }
                if let lastDate = lastMaintenanceDate {
                    let tripEnd = trip.endTime ?? trip.startTime ?? .distantPast
                    return tripEnd > lastDate
                }
                return true
            }
            let distance = tripsSince.compactMap(\.distance).reduce(0.0, +)

            if distance >= 50.0 {
                // Check if an active preventive maintenance alert already exists
                let activeAlertExists = issueReports.contains { report in
                    report.vehicleId == vehicle.id &&
                    report.category == "Preventive Maintenance" &&
                    report.status != "resolved" &&
                    report.status != "closed"
                }

                if !activeAlertExists {
                    // Create one in the database
                    let newReport = IssueReportRecord(
                        id: UUID(),
                        vehicleId: vehicle.id,
                        reportedBy: adminId ?? UUID(), // Reported by the manager/system
                        category: "Preventive Maintenance",
                        severity: "medium",
                        description: String(format: "Preventive check required: vehicle has completed %.1f km since last maintenance.", distance),
                        status: "open",
                        assignedTo: nil,
                        createdAt: Date(),
                        issuePhoto: nil
                    )

                    do {
                        try await IssueReportService.createIssueReport(newReport)
                        print("[PreventiveMaintenance] Successfully created alert for \(vehicle.make ?? "") \(vehicle.model ?? "")")
                    } catch {
                        print("[PreventiveMaintenance] Error creating alert: \(error)")
                    }
                }
            }
        }
    }
}
