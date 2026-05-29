//
//  InsuranceMonitorService.swift
//  Fleet
//
//  Daily expiry monitor for insurance documents.
//  • Reads expiry dates from ComplianceSettingsStore (in-memory / UserDefaults).
//  • Computes InsuranceAlertLevel for every vehicle.
//  • Creates in-app Notification records via NotificationService.
//  • Refreshes local UNUserNotificationCenter push schedules (30/15/7 days and expiry day).
//
//  Call InsuranceMonitorService.shared.runCheck(vehicles:userId:) from the
//  app's scene-phase onChange or from DashboardViewModel.loadData().
//

import Foundation
@preconcurrency import UserNotifications

@MainActor
@Observable
final class InsuranceMonitorService {

    static let shared = InsuranceMonitorService()
    private init() {}

    // Vehicles with active alerts (used by Dashboard to drive badge counts)
    private(set) var criticalVehicles:     [Vehicle] = []
    private(set) var highPriorityVehicles: [Vehicle] = []
    private(set) var warningVehicles:      [Vehicle] = []

    private let store = ComplianceSettingsStore.shared
    private let lastCheckKey = "fleet_insurance_monitor_last_check"

    // MARK: - Public API

    /// Run a daily expiry check.  Safe to call more frequently — throttled to once per calendar day.
    func runCheck(vehicles: [Vehicle], userId: UUID) async {
        guard shouldRunToday() else { return }
        markCheckedToday()
        await evaluate(vehicles: vehicles, userId: userId)
    }

    /// Force a check (ignores daily throttle — used after a new document upload).
    func forceCheck(vehicles: [Vehicle], userId: UUID) async {
        await evaluate(vehicles: vehicles, userId: userId)
    }

    // MARK: - Evaluation

    private func evaluate(vehicles: [Vehicle], userId: UUID) async {
        var critical:     [Vehicle] = []
        var highPriority: [Vehicle] = []
        var warning:      [Vehicle] = []

        for vehicle in vehicles {
            let key      = vehicle.licensePlate ?? vehicle.id.uuidString
            let settings = store.settings(for: key)
            guard let expiry = settings.insuranceExpiry else { continue }

            let days  = Calendar.current.dateComponents([.day], from: Date(), to: expiry).day ?? 0
            let level = InsuranceAlertLevel.level(for: days)

            switch level {
            case .critical:     critical.append(vehicle)
            case .highPriority: highPriority.append(vehicle)
            case .warning:      warning.append(vehicle)
            case .normal:       break
            }

            // Post in-app notification at the requested milestones, plus every expired day.
            if days < 0 || [30, 15, 7].contains(days) {
                await postInAppNotification(vehicle: vehicle, days: days, userId: userId, level: level)
            }
        }

        criticalVehicles     = critical
        highPriorityVehicles = highPriority
        warningVehicles      = warning

        // Refresh push schedules for ALL vehicles
        for vehicle in vehicles {
            let key = vehicle.licensePlate ?? vehicle.id.uuidString
            let settings = store.settings(for: key)
            refreshPushNotifications(settings: settings, vehicleKey: key)
        }
    }

    // MARK: - In-App Notification

    private func postInAppNotification(
        vehicle: Vehicle,
        days: Int,
        userId: UUID,
        level: InsuranceAlertLevel
    ) async {
        let plate = vehicle.licensePlate ?? "Unknown"
        let make  = "\(vehicle.make ?? "") \(vehicle.model ?? "")".trimmingCharacters(in: .whitespaces)

        let title: String
        let message: String
        let type: NotificationType

        if days < 0 {
            title   = "🔴 Insurance Expired"
            message = "Vehicle \(plate) (\(make)) insurance expired \(abs(days)) day\(abs(days) == 1 ? "" : "s") ago."
            type    = .alert
        } else {
            title   = "🟠 Insurance Expiring Soon"
            message = "Vehicle \(plate) (\(make)) insurance expires in \(days) day\(days == 1 ? "" : "s")."
            type    = .warning
        }

        // Deduplicate: only create one notification per vehicle per calendar day
        let dedupeKey = "ins_notif_\(vehicle.id.uuidString)_\(todayString())"
        guard UserDefaults.standard.string(forKey: dedupeKey) == nil else { return }
        UserDefaults.standard.set("sent", forKey: dedupeKey)

        let notification = Notification(
            id: UUID(),
            userId: userId,
            title: title,
            message: message,
            type: type,
            isRead: false,
            createdAt: Date()
        )
        try? await NotificationService.createNotification(notification)
    }

    // MARK: - Push Notification Schedule Refresh

    private func refreshPushNotifications(settings: ComplianceSettings, vehicleKey: String) {
        guard let expiry = settings.insuranceExpiry else { return }
        let center  = UNUserNotificationCenter.current()
        let prefix  = "ins_push_\(vehicleKey)_"

        center.getPendingNotificationRequests { requests in
            let toRemove = requests.filter { $0.identifier.hasPrefix(prefix) }.map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: toRemove)

            for days in [30, 15, 7, 0] {
                guard let triggerDate = Calendar.current.date(byAdding: .day, value: -days, to: expiry),
                      triggerDate > Date() else { continue }

                let content       = UNMutableNotificationContent()
                content.title     = days == 0 ? "🔴 Insurance Expires Today" : "⚠️ Insurance Expiry Reminder"
                content.body      = days == 0
                    ? "Vehicle \(vehicleKey) insurance expires today. Take action now."
                    : "Vehicle \(vehicleKey) insurance expires in \(days) day\(days == 1 ? "" : "s"). Take action now."
                content.sound     = .default
                content.badge     = 1

                var comps        = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
                comps.hour       = 9
                comps.minute     = 0

                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "\(prefix)\(days)",
                    content: content,
                    trigger: trigger
                )
                center.add(request)
            }
        }
    }

    // MARK: - Helpers

    private func shouldRunToday() -> Bool {
        guard let last = UserDefaults.standard.string(forKey: lastCheckKey) else { return true }
        return last != todayString()
    }

    private func markCheckedToday() {
        UserDefaults.standard.set(todayString(), forKey: lastCheckKey)
    }

    private func todayString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}
