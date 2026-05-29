import Foundation

// MARK: - Demand Forecasting Service
// On-device rules engine — no external API calls.
// Analyses inventory stock vs maintenance tasks and work orders to produce
// SparePartForecast results for the coming ~14 days.

enum DemandForecastingService {

    // MARK: - Public entry point

    static func forecast(
        inventory: [Inventory],
        tasks: [MaintenanceTask],
        workOrders: [WorkOrder]
    ) -> [SparePartForecast] {

        let pendingTasks  = tasks.filter { $0.status == .pending || $0.status == .inProgress }
        let openWorkOrders = workOrders.filter { $0.status == .open || $0.status == .inProgress }
        let completedRecently = recentlyCompletedTasks(tasks)

        var results: [SparePartForecast] = []

        for item in inventory {
            guard let name = item.partName, !name.isEmpty else { continue }
            let stock   = item.stockQuantity ?? 0
            let reorder = item.reorderLevel  ?? 0

            // --- Signal 1: Already at or below reorder level ---
            if stock <= reorder {
                results.append(SparePartForecast(
                    id: item.id,
                    partName: name,
                    urgency: .restock,
                    reason: "Stock (\(stock)) is at or below reorder level (\(reorder)).",
                    daysUntilStockout: 0,
                    currentStock: stock,
                    reorderLevel: reorder
                ))
                continue
            }

            // --- Signal 2: Pending tasks demand this part ---
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
                let taskSummary = matchingTasks.count == 1 ? "1 pending task" : "\(matchingTasks.count) pending tasks"
                results.append(SparePartForecast(
                    id: item.id,
                    partName: name,
                    urgency: matchingTasks.count >= 2 ? .high : .monitor,
                    reason: "\(taskSummary) likely require \(name).",
                    daysUntilStockout: days,
                    currentStock: stock,
                    reorderLevel: reorder
                ))
                continue
            }

            // --- Signal 3: Open work orders may need this part ---
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
                    reason: "\(matchingOrders.count) open work order(s) may require \(name).",
                    daysUntilStockout: days,
                    currentStock: stock,
                    reorderLevel: reorder
                ))
                continue
            }

            // --- Signal 4: High usage rate in last 30 days ---
            let recentUsage = recentTaskCount(for: name, in: completedRecently)
            if recentUsage >= 2 && reorder > 0 {
                // Estimate daily burn rate from last 30 days
                let dailyBurn = Double(recentUsage) / 30.0
                let buffer = Double(stock - reorder)
                let daysLeft = buffer > 0 ? Int(buffer / dailyBurn) : 0
                if daysLeft <= 14 {
                    results.append(SparePartForecast(
                        id: item.id,
                        partName: name,
                        urgency: .monitor,
                        reason: "\(recentUsage) uses in the past 30 days — stock may run low in ~\(daysLeft) days.",
                        daysUntilStockout: daysLeft,
                        currentStock: stock,
                        reorderLevel: reorder
                    ))
                }
            }
        }

        // Sort: most urgent first, then by days until stockout (ascending)
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
                   name.contains("pump") || name.contains("valve")
        case .other:
            return false
        }
    }

    /// Work orders don't have a description field, so match on priority + type inference.
    private static func workOrderMentionsPart(_ wo: WorkOrder, partName: String) -> Bool {
        // High/critical priority work orders are likely to need common repair parts
        let name = partName.lowercased()
        let isCritical = wo.priority == .critical || wo.priority == .high
        let isCommonRepairPart = name.contains("brake") || name.contains("oil") || name.contains("filter") ||
                                 name.contains("tyre") || name.contains("tire") || name.contains("belt") ||
                                 name.contains("fluid") || name.contains("pad") || name.contains("spark") ||
                                 name.contains("bearing") || name.contains("hose") || name.contains("pump")
        return isCritical && isCommonRepairPart
    }

    // MARK: - Usage History Helpers

    private static func recentlyCompletedTasks(_ tasks: [MaintenanceTask]) -> [MaintenanceTask] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return tasks.filter {
            $0.status == .completed &&
            ($0.scheduledDate ?? .distantPast) >= thirtyDaysAgo
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
        // Assume each task consumes 1 unit; spread over 14 days per task
        let daysPerTask = 14
        let totalDays = (buffer * daysPerTask) / upcomingDemand
        return max(0, totalDays)
    }
}
