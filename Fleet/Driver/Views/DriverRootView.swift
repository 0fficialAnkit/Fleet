import SwiftUI

struct DriverRootView: View {
    @State private var showProfile = false
    @State private var showNotifications = false

    var body: some View {
        NavigationStack {
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
            .tint(themeModel.driverPrimary)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        showNotifications = true
                    } label: {
                        Image(systemName: "bell.badge")
                            .font(.title3)
                            .foregroundStyle(themeModel.driverPrimary)
                    }

                    Button {
                        showProfile = true
                    } label: {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundStyle(themeModel.driverPrimary)
                    }
                }
            }
            .navigationDestination(isPresented: $showProfile) {
                DriverProfileView()
            }
            .navigationDestination(isPresented: $showNotifications) {
                NotificationsView()
            }
        }
    }
}

#Preview {
    DriverRootView()
        .environment(AuthViewModel())
}
