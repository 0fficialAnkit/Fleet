import SwiftUI

struct FleetManagerMainView: View {
    @State private var selectedTab = 0

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(themeModel.tabBar)

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = UIColor(themeModel.unselectedTab)

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(themeModel.textPrimary)]
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor(themeModel.textPrimary)]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    }

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

            // MARK: Reports
            ReportsView()
                .tabItem {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Reports")
                }
                .tag(2)
        }
        .tint(themeModel.selectedTab)
    }
}


#Preview {
    FleetManagerMainView()
        .environment(AuthViewModel())
}

