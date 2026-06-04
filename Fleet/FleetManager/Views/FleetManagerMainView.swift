import SwiftUI

struct FleetManagerMainView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2")
                }
                .tag(0)

            OrdersView()
                .tabItem {
                    Label("Orders", systemImage: "shippingbox")
                }
                .tag(1)

            FleetView()
                .tabItem {
                    Label("Fleet", systemImage: "person.2")
                }
                .tag(2)


            // MARK: Alerts
            ReportsView()
                .tabItem {
                    Image(systemName: "externaldrive.fill.trianglebadge.exclamationmark")
                    Text("Alerts")
                }
                .tag(3)
        }
        .tint(Color.teal)
    }
}

#Preview {
    FleetManagerMainView()
        .environment(AuthViewModel())
}
