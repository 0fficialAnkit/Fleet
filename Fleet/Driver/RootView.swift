import SwiftUI

struct RootTabView: View {

    var body: some View {

        TabView {

            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
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
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .tint(.green)
        .preferredColorScheme(.dark)
    }
}
