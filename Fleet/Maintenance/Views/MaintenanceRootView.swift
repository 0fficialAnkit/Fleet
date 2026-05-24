import SwiftUI

struct MaintenanceRootView: View {
    var body: some View {
        TabView {
            MaintenanceDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "gauge.with.dots.needle.33percent")
                }

            MaintenanceSchedulerView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar.badge.clock")
                }

            InventoryView()
                .tabItem {
                    Label("Inventory", systemImage: "archivebox.fill")
                }
        }
        .tint(themeModel.maintenancePrimary)
    }
}

#Preview {
    MaintenanceRootView()
        .environment(AuthViewModel())
}
