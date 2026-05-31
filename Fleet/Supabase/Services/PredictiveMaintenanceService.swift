// PredictiveMaintenanceService.swift
// Fleet
//
// On-device rules engine that analyses vehicle usage data
// and produces PredictiveMaintenanceAlert values for each at-risk vehicle.

import Foundation

enum PredictiveMaintenanceService {

    // MARK: - Inspection keyword patterns to watch for
    private static let inspectionKeywords: [String: String] = [
        "brake":  "Brake system anomaly",
        "oil":    "Engine oil concern",
        "tire":   "Tyre/wheel issue",
        "tyre":   "Tyre/wheel issue",
        "engine": "Engine anomaly",
        "leak":   "Fluid leak detected",
        "smoke":  "Engine smoke reported",
        "battery":"Battery concern",
        "light":  "Warning light noticed",
        "coolant":"Coolant concern",
        "steering":"Steering concern",
    ]

    // Days-since-service thresholds by vehicle type
    private static func overdueThreshold(for type: VehicleType?) -> Int {
        switch type {
        case .twoWheeler: return 60
        case .car:        return 90
        case .truck:      return 120
        case .none:       return 90
        }
    }

    // MARK: - Main analysis entry point

    /// Runs all rules against the provided data and returns one alert per flagged vehicle.
    /// All data is already loaded by DashboardViewModel — no network call.
    static func analyze(
        vehicles: [Vehicle],
        trips: [Trip],
        inspections: [VehicleInspection],
        issueReports: [IssueReportRecord],
        maintenanceHistory: [MaintenanceHistory]
    ) -> [PredictiveMaintenanceAlert] {

        let now = Date()
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        let sevenDaysAgo  = calendar.date(byAdding: .day, value: -7,  to: now) ?? now

        var alerts: [PredictiveMaintenanceAlert] = []

        for vehicle in vehicles {
            var signals: [PredictiveMaintenanceAlert.TriggerSignal] = []

            let vehicleTrips = trips.filter { $0.vehicleId == vehicle.id }
            let completedTrips = vehicleTrips.filter { $0.status == .completed }
            let totalKM = completedTrips.compactMap(\.distance).reduce(0, +)

            // ── Signal 1: Manual maintenance status ─────────────────────────
            if vehicle.status == .maintenance {
                signals.append(.manualMaintenanceStatus)
            }

            // ── Signal 2: Distance threshold (warn at 80%) ──────────────────
            let threshold = vehicle.vehicleType?.maintenanceThresholdKM ?? 10_000
            let pct = totalKM / threshold
            if pct >= 0.80 {
                signals.append(.distanceThreshold(pct: pct))
            }

            // ── Signal 3: Open high/critical issue reports (last 30 days) ───
            let openCritical = issueReports.filter { report in
                report.vehicleId == vehicle.id &&
                report.status != "resolved" && report.status != "closed" &&
                (report.severity == "high" || report.severity == "critical") &&
                (report.createdAt ?? .distantPast) >= thirtyDaysAgo
            }
            if !openCritical.isEmpty {
                signals.append(.openCriticalDefect(count: openCritical.count))
            }

            // ── Signal 4: Inspection keyword patterns ────────────────────────
            let vehicleInspections = inspections.filter { $0.vehicleId == vehicle.id }
            var keywordHits: [String: Int] = [:]
            for inspection in vehicleInspections {
                let notes = (inspection.notes ?? "").lowercased()
                for (keyword, _) in inspectionKeywords {
                    if notes.contains(keyword) {
                        keywordHits[keyword, default: 0] += 1
                    }
                }
            }
            // Pick the most frequently flagged keyword (if any)
            if let (topKeyword, count) = keywordHits.max(by: { $0.value < $1.value }) {
                signals.append(.inspectionKeyword(keyword: topKeyword, count: count))
            }

            // ── Signal 5: Usage spike (last 7 days vs. 30-day daily avg) ────
            let recentCount = completedTrips.filter {
                ($0.endTime ?? .distantFuture) >= sevenDaysAgo
            }.count
            let last30Count = completedTrips.filter {
                ($0.endTime ?? .distantFuture) >= thirtyDaysAgo
            }.count
            let dailyAvg30 = Double(last30Count) / 30.0
            let dailyAvgRecent = Double(recentCount) / 7.0
            // Flag if last-7-day rate is >2× the 30-day average AND meaningful volume
            if dailyAvg30 > 0.1 && dailyAvgRecent > dailyAvg30 * 2 {
                signals.append(.usageSpike(recentTrips: recentCount, avgTrips: dailyAvg30 * 7))
            }

            // ── Signal 6: Overdue for scheduled service ──────────────────────
            let lastService = maintenanceHistory
                .filter { $0.vehicleId == vehicle.id }
                .compactMap(\.completedAt)
                .max()
            let overdueAfter = overdueThreshold(for: vehicle.vehicleType)
            if let lastDate = lastService {
                let daysSince = calendar.dateComponents([.day], from: lastDate, to: now).day ?? 0
                if daysSince >= overdueAfter {
                    signals.append(.overdueService(daysSince: daysSince))
                }
            } else if !completedTrips.isEmpty {
                // Has trips but zero maintenance history — flag it
                signals.append(.overdueService(daysSince: overdueAfter))
            }

            guard !signals.isEmpty else { continue }

            // ── Build the alert ──────────────────────────────────────────────
            let severity = computeSeverity(signals: signals, pct: pct)
            let (reason, recommendation) = buildMessage(
                signals: signals, vehicle: vehicle, pct: pct,
                keywordHits: keywordHits, openCritical: openCritical.count
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

        // Sort: critical first, then by vehicle name
        return alerts.sorted {
            if $0.severity != $1.severity { return $0.severity > $1.severity }
            let name0 = "\($0.vehicle.make ?? "") \($0.vehicle.model ?? "")"
            let name1 = "\($1.vehicle.make ?? "") \($1.vehicle.model ?? "")"
            return name0 < name1
        }
    }

    // MARK: - Severity

    private static func computeSeverity(
        signals: [PredictiveMaintenanceAlert.TriggerSignal],
        pct: Double
    ) -> PredictiveMaintenanceAlert.AlertSeverity {
        for signal in signals {
            switch signal {
            case .manualMaintenanceStatus:      return .critical
            case .openCriticalDefect:           return .critical
            case .distanceThreshold where pct >= 1.0: return .critical
            default: break
            }
        }
        return .warning
    }

    // MARK: - Human-readable message

    private static func buildMessage(
        signals: [PredictiveMaintenanceAlert.TriggerSignal],
        vehicle: Vehicle,
        pct: Double,
        keywordHits: [String: Int],
        openCritical: Int
    ) -> (reason: String, recommendation: String) {

        // Priority order for the primary reason shown on the card
        for signal in signals {
            switch signal {
            case .manualMaintenanceStatus:
                return (
                    "Flagged for maintenance",
                    "Review the maintenance queue and assign a work order."
                )
            case .openCriticalDefect(let count):
                return (
                    "\(count) unresolved critical defect\(count > 1 ? "s" : "") reported",
                    "Inspect the vehicle immediately before the next trip."
                )
            case .distanceThreshold(let p):
                let pctStr = String(format: "%.0f", p * 100)
                let threshold = vehicle.vehicleType?.maintenanceThresholdKM ?? 10_000
                return (
                    "\(pctStr)% of \(Int(threshold)) km service interval reached",
                    "Schedule a service before the threshold is exceeded."
                )
            case .overdueService(let days):
                return (
                    "No maintenance recorded in \(days)+ days",
                    "Book the vehicle in for a routine check-up."
                )
            case .inspectionKeyword(let keyword, let count):
                let label = inspectionKeywords[keyword] ?? keyword.capitalized
                return (
                    "\(label) flagged in \(count) inspection\(count > 1 ? "s" : "")",
                    "Investigate the \(keyword) system and address before the next trip."
                )
            case .usageSpike(let recent, let avg):
                return (
                    "Heavy recent usage (\(recent) trips vs \(String(format: "%.1f", avg)) avg)",
                    "Perform an early check given the elevated workload."
                )
            }
        }
        return ("Maintenance recommended", "Schedule a routine inspection.")
    }
}
