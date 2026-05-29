// PredictiveMaintenance.swift
// Fleet
//
// Model for AI-driven predictive maintenance alerts.

import Foundation

/// A single predictive maintenance alert derived from vehicle usage analysis.
struct PredictiveMaintenanceAlert: Identifiable {
    let id: UUID          // same as vehicle.id — one alert per vehicle
    let vehicle: Vehicle
    let reason: String           // Short reason shown on the card
    let recommendation: String   // Recommended action for the fleet manager
    let severity: AlertSeverity
    let triggerSignals: [TriggerSignal] // all signals that fired

    enum AlertSeverity: Comparable {
        case warning
        case critical
    }

    enum TriggerSignal {
        case distanceThreshold(pct: Double)        // % of threshold reached
        case openCriticalDefect(count: Int)
        case inspectionKeyword(keyword: String, count: Int)
        case usageSpike(recentTrips: Int, avgTrips: Double)
        case overdueService(daysSince: Int)
        case manualMaintenanceStatus
    }
}
