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

            OrdersView()
                .tabItem {
                    Image(systemName: "shippingbox.fill")
                    Text("Orders")
                }
                .tag(1)

            // MARK: Fleet — Drivers + Maintenance
            FleetView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Fleet")
                }
                .tag(2)


            // MARK: Reports
            ReportsView()
                .tabItem {
                    Image(systemName: "externaldrive.fill.trianglebadge.exclamationmark")
                    Text("Reports")
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
