import SwiftUI

struct FleetManagerMainView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            // MARK: Dashboard (profile access via toolbar)
            DashboardView()
                .tabItem {
                    Image(systemName: "square.grid.2x2.fill")
                    Text("Dashboard")
                }
                .tag(0)

            // MARK: Fleet — Drivers + Maintenance
            FleetView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Fleet")
                }
                .tag(1)

            // MARK: Orders
            OrdersView()
                .tabItem {
                    Image(systemName: "shippingbox.fill")
                    Text("Orders")
                }
                .tag(2)

            // MARK: Reports
            ReportsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Reports")
                }
                .tag(3)
        }
        .tint(Color.blue)
    }
}


#Preview {
    FleetManagerMainView()
        .environment(AuthViewModel())
}

