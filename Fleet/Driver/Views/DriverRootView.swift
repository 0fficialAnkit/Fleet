import SwiftUI

struct DriverRootView: View {

    var body: some View {

        TabView {

            DriverDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }

            DriverTripsView()
                .tabItem {
                    Label("Trips", systemImage: "road.lanes")
                }

            DriverFuelView()
                .tabItem {
                    Label("Fuel", systemImage: "fuelpump.fill")
                }
        }
        .tint(Color.green)
    }
}

#Preview {
    DriverRootView()
        .environment(AuthViewModel())
}