import SwiftUI

struct DriverRootView: View {

    var body: some View {

        TabView {

            DriverDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.doc.horizontal.fill")
                }

            DriverTripsView()
                .tabItem {
                    Label("Trips", systemImage: "map.fill")
                }

            DriverChecklistView()
                .tabItem {
                    Label("Checklist", systemImage: "checklist")
                }

            DriverFuelView()
                .tabItem {
                    Label("Fuel", systemImage: "fuelpump.fill")
                }

            DriverProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
        .tint(.blue)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    DriverRootView()
}
