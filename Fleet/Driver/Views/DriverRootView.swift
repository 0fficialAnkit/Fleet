import SwiftUI

struct DriverRootView: View {
    var body: some View {
        TabView {
            DriverDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2")
                }

            DriverTripsView()
                .tabItem {
                    Label("Trips", systemImage: "road.lanes")
                }

            DriverFuelView()
                .tabItem {
                    Label("Fuel", systemImage: "fuelpump")
                }
        }
        .tint(Color.green)
    }
}

#Preview {
    DriverRootView()
        .environment(AuthViewModel())
}
