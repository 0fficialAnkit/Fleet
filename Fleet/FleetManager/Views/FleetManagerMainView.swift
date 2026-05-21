import SwiftUI

struct FleetManagerMainView: View {
    @State private var selectedTab = 0
    
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
                    Image(systemName: "truck.box.fill")
                    Text("Vehicles")
                }
                .tag(1)
            
            EmployeesView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Employees")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                    Text("Profile")
                }
                .tag(3)
        }
        .tint(themeModel.accent)
    }
}

#Preview {
    FleetManagerMainView()
}
