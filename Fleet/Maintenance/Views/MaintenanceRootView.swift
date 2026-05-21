import SwiftUI

struct MaintenanceRootView: View {
    var body: some View {
        TabView {
            MaintenanceDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.doc.horizontal.fill")
                }
            
            WorkOrderListView()
                .tabItem {
                    Label("Work Orders", systemImage: "wrench.and.screwdriver.fill")
                }
            
            InventoryView()
                .tabItem {
                    Label("Inventory", systemImage: "shippingbox.fill")
                }
            
            MaintenanceProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
        .tint(.blue)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MaintenanceRootView()
}
