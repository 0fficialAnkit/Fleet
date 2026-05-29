import SwiftUI

struct MaintenanceRootView: View {
    @State private var selectedTab: Int = 0
    @State private var schedulerViewModel = MaintenanceSchedulerViewModel()

    var body: some View {
        TabView(selection: $selectedTab) {
            MaintenanceDashboardView(
                selectedTab: $selectedTab,
                schedulerViewModel: schedulerViewModel
            )
            .tabItem {
                Label("Dashboard", systemImage: "gauge.with.dots.needle.33percent")
            }
            .tag(0)

            MaintenanceSchedulerView(viewModel: schedulerViewModel)
                .tabItem {
                    Label("Schedule", systemImage: "calendar.badge.clock")
                }
                .tag(1)
        }
        .tint(Color.brown)
    }
}

#Preview {
    MaintenanceRootView()
        .environment(AuthViewModel())
}