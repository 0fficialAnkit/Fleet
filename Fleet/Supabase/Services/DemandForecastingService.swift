import Foundation

// MARK: - Demand Forecasting Service
// On-device rules engine — no external API calls.
// Analyses inventory stock, maintenance task history, and work orders to
// produce SparePartForecast results based on actual demand signals.

enum DemandForecastingService {

    // MARK: - Public entry point

    static func forecast(
        inventory: [Inventory],
        tasks: [MaintenanceTask],
        workOrders: [WorkOrder]
    ) -> [SparePartForecast] {

        let pendingTasks      = tasks.filter { $0.status == .pending || $0.status == .inProgress }
        let openWorkOrders    = workOrders.filter { $0.status == .open || $0.status == .inProgress }
        let completedLast30   = recentlyCompletedTasks(tasks, days: 30)
        let completedLast7    = recentlyCompletedTasks(tasks, days: 7)

        var results: [SparePartForecast] = []

        for item in inventory {
            guard let name = item.partName, !name.isEmpty else { continue }
            let stock   = item.stockQuantity ?? 0
            let reorder = item.reorderLevel  ?? 0

            // ── Signal 1: Already at or below reorder level ─────────────────
            if stock <= reorder {
                let usageLast30 = recentTaskCount(for: name, in: completedLast30)
                let dailyBurn   = usageLast30 > 0 ? Double(usageLast30) / 30.0 : 0.0
                let burnNote    = usageLast30 > 0
                    ? " Used \(usageLast30)× in last 30 days (≈\(String(format: "%.1f", dailyBurn * 7))/wk)."
                    : ""
                results.append(SparePartForecast(
                    id: item.id,
                    partName: name,
                    urgency: .restock,
                    reason: "Stock (\(stock)) is at or below reorder level (\(reorder)).\(burnNote)",
                    daysUntilStockout: 0,
                    currentStock: stock,
                    reorderLevel: reorder
                ))
                continue
            }

            // ── Signal 2: High usage velocity this week ──────────────────────
            let usageLast7  = recentTaskCount(for: name, in: completedLast7)
            let usageLast30 = recentTaskCount(for: name, in: completedLast30)

            if usageLast7 >= 2 {
                // Weekly velocity is high — project forward
                let dailyBurn = Double(usageLast7) / 7.0
                let buffer    = Double(stock - reorder)
                let daysLeft  = buffer > 0 ? Int(buffer / dailyBurn) : 0
                results.append(SparePartForecast(
                    id: item.id,
                    partName: name,
                    urgency: daysLeft <= 7 ? .high : .monitor,
                    reason: "Used \(usageLast7)× this week — \(usageLast30)× last 30 days. At this rate stock lasts ~\(daysLeft) more days.",
                    daysUntilStockout: daysLeft,
                    currentStock: stock,
                    reorderLevel: reorder
                ))
                continue
            }

            // ── Signal 3: Pending tasks demand this part ─────────────────────
            let matchingTasks = pendingTasks.filter {
                descriptionMentionsPart($0.description, partName: name) ||
                taskTypeMentionsPart($0.taskType, partName: name)
            }
            if !matchingTasks.isEmpty {
                let days = estimatedDaysUntilStockout(
                    stock: stock,
                    reorder: reorder,
                    upcomingDemand: matchingTasks.count
                )
                let taskSummary = matchingTasks.count == 1
                    ? "1 pending task requires"
                    : "\(matchingTasks.count) pending tasks require"
                results.append(SparePartForecast(
                    id: item.id,
                    partName: name,
                    urgency: matchingTasks.count >= 2 ? .high : .monitor,
                    reason: "\(taskSummary) \(name). \(usageLast30 > 0 ? "Also used \(usageLast30)× last 30 days." : "")",
                    daysUntilStockout: days,
                    currentStock: stock,
                    reorderLevel: reorder
                ))
                continue
            }

            // ── Signal 4: Open work orders likely need this part ─────────────
            let matchingOrders = openWorkOrders.filter {
                workOrderMentionsPart($0, partName: name)
            }
            if !matchingOrders.isEmpty {
                let days = estimatedDaysUntilStockout(
                    stock: stock,
                    reorder: reorder,
                    upcomingDemand: matchingOrders.count
                )
                results.append(SparePartForecast(
                    id: item.id,
                    partName: name,
                    urgency: .high,
                    reason: "\(matchingOrders.count) open work order(s) likely need \(name). \(usageLast30 > 0 ? "Also used \(usageLast30)× last 30 days." : "")",
                    daysUntilStockout: days,
                    currentStock: stock,
                    reorderLevel: reorder
                ))
                continue
            }

            // ── Signal 5: Moderate usage in last 30 days trending up ─────────
            if usageLast30 >= 2 && reorder > 0 {
                let dailyBurn = Double(usageLast30) / 30.0
                let buffer    = Double(stock - reorder)
                let daysLeft  = buffer > 0 ? Int(buffer / dailyBurn) : 0
                if daysLeft <= 21 {
                    results.append(SparePartForecast(
                        id: item.id,
                        partName: name,
                        urgency: .monitor,
                        reason: "Used \(usageLast30)× in last 30 days. At current rate, stock may reach reorder level in ~\(daysLeft) days.",
                        daysUntilStockout: daysLeft,
                        currentStock: stock,
                        reorderLevel: reorder
                    ))
                }
            }
        }

        // Sort: most urgent first, then by days until stockout ascending
        return results.sorted {
            if $0.urgency != $1.urgency { return $0.urgency > $1.urgency }
            let d0 = $0.daysUntilStockout ?? Int.max
            let d1 = $1.daysUntilStockout ?? Int.max
            return d0 < d1
        }
    }

    // MARK: - Keyword Matching Helpers

    /// Check if a task description mentions a part name by fuzzy token matching.
    private static func descriptionMentionsPart(_ description: String?, partName: String) -> Bool {
        guard let desc = description?.lowercased(), !desc.isEmpty else { return false }
        let tokens = partName.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 3 }
        return tokens.contains { desc.contains($0) }
    }

    /// Map task types to common part categories.
    private static func taskTypeMentionsPart(_ type: MaintenanceTaskType?, partName: String) -> Bool {
        guard let type else { return false }
        let name = partName.lowercased()
        switch type {
        case .oilChange:
            return name.contains("oil") || name.contains("filter") || name.contains("gasket")
        case .tireRotation:
            return name.contains("tyre") || name.contains("tire") || name.contains("wheel") || name.contains("rim")
        case .inspection:
            return name.contains("brake") || name.contains("pad") || name.contains("belt") || name.contains("fluid")
        case .repair:
            return name.contains("spark") || name.contains("bearing") || name.contains("seal") ||
                   name.contains("hose") || name.contains("belt") || name.contains("brake") ||
                   name.contains("pump") || name.contains("valve") || name.contains("mirror") ||
                   name.contains("light") || name.contains("clutch")
        case .other:
            return false
        }
    }

    /// Work orders don't have a description field — match on priority + common repair parts.
    private static func workOrderMentionsPart(_ wo: WorkOrder, partName: String) -> Bool {
        let name = partName.lowercased()
        let isCritical = wo.priority == .critical || wo.priority == .high
        let isCommonRepairPart = name.contains("brake") || name.contains("oil") || name.contains("filter") ||
                                 name.contains("tyre") || name.contains("tire") || name.contains("belt") ||
                                 name.contains("fluid") || name.contains("pad") || name.contains("spark") ||
                                 name.contains("bearing") || name.contains("hose") || name.contains("pump") ||
                                 name.contains("mirror") || name.contains("light") || name.contains("clutch")
        return isCritical && isCommonRepairPart
    }

    // MARK: - Usage History Helpers

    private static func recentlyCompletedTasks(_ tasks: [MaintenanceTask], days: Int) -> [MaintenanceTask] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return tasks.filter {
            $0.status == .completed &&
            ($0.scheduledDate ?? .distantPast) >= cutoff
        }
    }

    private static func recentTaskCount(for partName: String, in tasks: [MaintenanceTask]) -> Int {
        tasks.filter {
            descriptionMentionsPart($0.description, partName: partName) ||
            taskTypeMentionsPart($0.taskType, partName: partName)
        }.count
    }

    // MARK: - Stockout Estimation

    private static func estimatedDaysUntilStockout(
        stock: Int,
        reorder: Int,
        upcomingDemand: Int
    ) -> Int? {
        guard upcomingDemand > 0, stock > reorder else { return nil }
        let buffer = stock - reorder
        // Assume each task consumes ~1 unit spread over 14 days
        let totalDays = (buffer * 14) / upcomingDemand
        return max(0, totalDays)
    }
}
