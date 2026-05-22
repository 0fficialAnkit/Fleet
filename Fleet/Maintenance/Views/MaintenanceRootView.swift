import SwiftUI

struct MaintenanceRootView: View {
    var body: some View {
        TabView {
            MaintenanceDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "gauge.with.dots.needle.33percent")
                }

            WorkOrderListView()
                .tabItem {
                    Label("Work Orders", systemImage: "wrench.and.screwdriver.fill")
                }

            InventoryView()
                .tabItem {
                    Label("Inventory", systemImage: "archivebox.fill")
                }

            MaintenanceProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
        .tint(themeModel.maintenancePrimary)
    }
}

#Preview {
    MaintenanceRootView()
}
