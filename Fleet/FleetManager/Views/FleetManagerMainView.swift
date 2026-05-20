import SwiftUI

struct FleetManagerMainView: View {
    @State private var selectedTab = 0
    
    init() {
        // Customize TabBar appearance for a sleek, modern look
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(themeModel.tabBar)
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = UIColor(themeModel.unselectedTab)
        
        // Customize NavigationBar appearance to match the theme when using native NavigationStack
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
            DashboardView()
                .tabItem {
                    Image(systemName: "square.grid.2x2.fill")
                    Text("Dashboard")
                }
                .tag(0)
            
            VehiclesView()
                .tabItem {
                    Image(systemName: "car.fill")
                    Text("Vehicles")
                }
                .tag(1)
            
            EmployeesView()
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("Employees")
                }
                .tag(2)
            
            Text("Orders View") // Placeholder
                .tabItem {
                    Image(systemName: "doc.text.fill")
                    Text("Orders")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
                .tag(4)
        }
        .tint(themeModel.selectedTab)
    }
}

#Preview {
    FleetManagerMainView()
}
