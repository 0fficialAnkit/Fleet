//
//  MaintenanceModels.swift
//  Fleet
//
//  Created by Codex on 20/05/26.
//

import SwiftUI

enum MaintenanceScreenTab: String {
    case calendar = "Calendar"
    case orders = "Orders"
    case parts = "Parts"
}

struct MaintenanceCalendarService: Identifiable {
    let id = UUID()
    let title: String
    let vehicle: String
    let time: String
    let tint: Color
}

struct MaintenanceWorkOrder: Identifiable {
    let id = UUID()
    let title: String
    let code: String
    let vehicle: String
    let estimate: String
    let assignee: String
    let priority: String
    let priorityTint: Color
}

struct MaintenanceInventoryMetric: Identifiable {
    let id = UUID()
    let symbol: String
    let value: String
    let title: String
    let tint: Color
}

struct MaintenanceInventoryAlert: Identifiable {
    let id = UUID()
    let title: String
    let value: String
}

struct MaintenancePart: Identifiable {
    let id = UUID()
    let title: String
    let code: String
    let quantity: String
    let unitLabel: String
    let category: String
    let minimumText: String
    let progress: CGFloat
    let tint: Color
}

enum MaintenanceSampleData {
    static let months = [
        "January 2026", "February 2026", "March 2026", "April 2026",
        "May 2026", "June 2026", "July 2026"
    ]

    static let calendarDays: [[String]] = [
        ["", "", "", "", "", "1", "2"],
        ["3", "4", "5", "6", "7", "8", "9"],
        ["10", "11", "12", "13", "14", "15", "16"],
        ["17", "18", "19", "20", "21", "22", "23"],
        ["24", "25", "26", "27", "28", "29", "30"],
        ["31", "", "", "", "", "", ""]
    ]

    static let calendarMarkers: [String: Color] = [
        "20": Color.orange,
        "22": Color(red: 1.0, green: 0.24, blue: 0.46),
        "24": Color(red: 0.74, green: 0.38, blue: 1.0),
        "26": Color(red: 0.12, green: 0.49, blue: 1.0)
    ]

    static let calendarServices: [String: [MaintenanceCalendarService]] = [
        "19": [
            MaintenanceCalendarService(
                title: "Oil Change",
                vehicle: "TRK-001",
                time: "09:00",
                tint: Color(red: 0.05, green: 0.49, blue: 1.0)
            )
        ]
    ]

    static let workOrders: [MaintenanceWorkOrder] = [
        MaintenanceWorkOrder(
            title: "Engine Fault Codes",
            code: "WO-039",
            vehicle: "BUS-003",
            estimate: "3h",
            assignee: "Riley",
            priority: "HIGH",
            priorityTint: Color(red: 1.0, green: 0.24, blue: 0.46)
        ),
        MaintenanceWorkOrder(
            title: "Oil Change",
            code: "WO-038",
            vehicle: "TRK-001",
            estimate: "45m",
            assignee: "Sam",
            priority: "MEDIUM",
            priorityTint: Color(red: 1.0, green: 0.67, blue: 0.06)
        )
    ]

    static let inventoryMetrics: [MaintenanceInventoryMetric] = [
        MaintenanceInventoryMetric(symbol: "shippingbox", value: "6", title: "Total SKUs", tint: Color(red: 0.05, green: 0.49, blue: 1.0)),
        MaintenanceInventoryMetric(symbol: "arrow.down.right", value: "3", title: "Low Stock", tint: Color(red: 1.0, green: 0.24, blue: 0.46)),
        MaintenanceInventoryMetric(symbol: "cube", value: "4", title: "Categories", tint: Color(red: 0.20, green: 0.91, blue: 0.38))
    ]

    static let inventoryAlerts: [MaintenanceInventoryAlert] = [
        MaintenanceInventoryAlert(title: "Brake Pads (Front)", value: "3/8 sets"),
        MaintenanceInventoryAlert(title: "Wiper Blades", value: "7/8 pairs"),
        MaintenanceInventoryAlert(title: "12V Battery", value: "2/4 units")
    ]

    static let parts: [MaintenancePart] = [
        MaintenancePart(
            title: "Engine Oil Filter",
            code: "F-2234",
            quantity: "24",
            unitLabel: "units",
            category: "Engine",
            minimumText: "Min: 10 · $8.50/unit",
            progress: 1.0,
            tint: Color(red: 0.05, green: 0.49, blue: 1.0)
        ),
        MaintenancePart(
            title: "Brake Pads (Front)",
            code: "B-1102",
            quantity: "3",
            unitLabel: "sets",
            category: "Brakes",
            minimumText: "Min: 8 · $42.00/unit",
            progress: 0.19,
            tint: Color(red: 1.0, green: 0.24, blue: 0.46)
        )
    ]
}
