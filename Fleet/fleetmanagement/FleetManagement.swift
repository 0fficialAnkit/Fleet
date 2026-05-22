//
//  FleetManagement.swift
//  Fleet
//
//  Created by Codex on 19/05/26.
//

import SwiftUI

struct FleetManagement: View {
    @State private var selectedTab: FleetManagementTab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Dashboard", systemImage: "house", value: FleetManagementTab.dashboard) {
                FleetDashboardView()
            }

            Tab("Vehicles", systemImage: "car", value: FleetManagementTab.vehicles) {
                FleetTabPage(
                    title: "Vehicles",
                    subtitle: "Track fleet availability, active routes, and vehicle health.",
                    symbol: "car.2",
                    tint: .blue
                )
            }

            Tab("Team", systemImage: "person.2", value: FleetManagementTab.team) {
                FleetTabPage(
                    title: "Team",
                    subtitle: "Manage drivers, shifts, and route assignments.",
                    symbol: "person.2",
                    tint: .green
                )
            }

            Tab("Service", systemImage: "wrench.adjustable", value: FleetManagementTab.service) {
                FleetTabPage(
                    title: "Service",
                    subtitle: "Review maintenance alerts, work orders, and inspections.",
                    symbol: "wrench.and.screwdriver",
                    tint: .orange
                )
            }

            Tab("Profile", systemImage: "person.crop.circle", value: FleetManagementTab.profile) {
                FleetTabPage(
                    title: "Profile",
                    subtitle: "Fleet manager preferences, reports, and account details.",
                    symbol: "person.crop.circle",
                    tint: .pink
                )
            }
        }
        .tint(.blue)
        .preferredColorScheme(.dark)
    }
}

#Preview("Fleet Management") {
    FleetManagement()
}
