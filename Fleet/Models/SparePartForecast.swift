import Foundation

// MARK: - Forecast Urgency

enum ForecastUrgency: Int, Comparable, CustomStringConvertible {
    case restock = 3   // already at/below reorder level — restock now
    case high    = 2   // will likely run out within ~14 days
    case monitor = 1   // elevated usage, watch carefully

    static func < (lhs: ForecastUrgency, rhs: ForecastUrgency) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var description: String {
        switch self {
        case .restock: return "Restock Now"
        case .high:    return "High Demand"
        case .monitor: return "Monitor"
        }
    }

    var icon: String {
        switch self {
        case .restock: return "exclamationmark.triangle.fill"
        case .high:    return "arrow.up.circle.fill"
        case .monitor: return "eye.fill"
        }
    }
}

// MARK: - SparePartForecast

struct SparePartForecast: Identifiable {
    let id: UUID            // same as the Inventory item's id
    let partName: String
    let urgency: ForecastUrgency
    let reason: String              // human-readable explanation
    let daysUntilStockout: Int?     // nil = not calculable
    let currentStock: Int
    let reorderLevel: Int
}
