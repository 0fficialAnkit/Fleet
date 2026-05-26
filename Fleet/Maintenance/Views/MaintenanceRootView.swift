import SwiftUI

struct MaintenanceRootView: View {
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MaintenanceDashboardView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Dashboard", systemImage: "gauge.with.dots.needle.33percent")
                }
                .tag(0)

            MaintenanceSchedulerView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar.badge.clock")
                }
                .tag(1)

            InventoryView()
                .tabItem {
                    Label("Inventory", systemImage: "archivebox.fill")
                }
                .tag(2)
        }
        .tint(themeModel.maintenancePrimary)
    }
}

#Preview {
    MaintenanceRootView()
        .environment(AuthViewModel())
}
