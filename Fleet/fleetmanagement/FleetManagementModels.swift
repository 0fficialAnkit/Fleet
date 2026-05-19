//
//  FleetManagementModels.swift
//  Fleet
//
//  Created by Codex on 19/05/26.
//

import SwiftUI

enum FleetManagementTab: Hashable {
    case dashboard
    case vehicles
    case team
    case service
    case profile
}

struct FleetStat: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let change: String
    let symbol: String
    let tint: Color
}

struct FleetBar: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

struct FleetTrip: Identifiable {
    let id = UUID()
    let vehicle: String
    let driver: String
    let route: String
    let eta: String
    let progress: Double
}

struct FleetAlert: Identifiable {
    let id = UUID()
    let vehicle: String
    let message: String
    let time: String
    let tint: Color
}

enum FleetSampleData {
    static let stats = [
        FleetStat(title: "Active Vehicles", value: "24/30", change: "+2 today", symbol: "car.fill", tint: .blue),
        FleetStat(title: "Fleet Utilization", value: "80%", change: "+5% vs last week", symbol: "chart.line.uptrend.xyaxis", tint: .green),
        FleetStat(title: "Active Drivers", value: "21", change: "3 on break", symbol: "person.2.fill", tint: .orange),
        FleetStat(title: "Fuel Usage", value: "1.8k L", change: "-8% this week", symbol: "fuelpump.fill", tint: .pink)
    ]

    static let utilization = [
        FleetBar(label: "6am", value: 0.18),
        FleetBar(label: "8am", value: 0.72),
        FleetBar(label: "10am", value: 0.88),
        FleetBar(label: "12pm", value: 0.80),
        FleetBar(label: "2pm", value: 0.96),
        FleetBar(label: "4pm", value: 0.76),
        FleetBar(label: "6pm", value: 0.50),
        FleetBar(label: "8pm", value: 0.26)
    ]

    static let trips = [
        FleetTrip(vehicle: "TRK-007", driver: "Alex Chen", route: "Warehouse -> Depot A", eta: "ETA 14 min", progress: 0.65),
        FleetTrip(vehicle: "VAN-015", driver: "Maria Lopez", route: "HQ -> Client Site B", eta: "ETA 28 min", progress: 0.32),
        FleetTrip(vehicle: "BUS-003", driver: "Jordan Kim", route: "Terminal -> Airport", eta: "ETA 6 min", progress: 0.88)
    ]

    static let alerts = [
        FleetAlert(vehicle: "TRK-007", message: "Oil change due in 200km", time: "2m ago", tint: .orange),
        FleetAlert(vehicle: "VAN-012", message: "Tire pressure low - front left", time: "15m ago", tint: .pink),
        FleetAlert(vehicle: "BUS-003", message: "Maintenance scheduled tomorrow", time: "1h ago", tint: .blue)
    ]

    static let fuelTrend = [0.34, 0.47, 0.53, 0.48, 0.42, 0.66, 0.79, 0.76, 0.67, 0.45, 0.22, 0.17, 0.15]
}
