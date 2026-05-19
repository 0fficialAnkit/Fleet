import SwiftUI

struct DriverRootView: View {

    var body: some View {

        TabView {

            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.doc.horizontal.fill")
                }

            TripsView()
                .tabItem {
                    Label("Trips", systemImage: "map.fill")
                }

            ChecklistView()
                .tabItem {
                    Label("Checklist", systemImage: "checklist")
                }

            FuelView()
                .tabItem {
                    Label("Fuel", systemImage: "fuelpump.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
        .tint(.green)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    DriverRootView()
}
