import SwiftUI

enum FleetTab: String, CaseIterable {
    case vehicles = "Vehicles"
    case maintenance = "Maintenance"
}

struct FleetView: View {
    @State private var selectedTab: FleetTab = .vehicles
    
    @State private var vehiclesViewModel = VehiclesViewModel()
    @State private var maintenanceViewModel = MaintenanceViewModel()
    
    @State private var isShowingAddVehicle = false
    @State private var isShowingAddMaintenance = false
    
    init() {
        // Customize segmented control appearance
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(themeModel.info)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor(themeModel.textSecondary)], for: .normal)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Picker("Fleet Section", selection: $selectedTab) {
                        ForEach(FleetTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, themeModel.spacingMD)
                    .padding(.vertical, themeModel.spacingMD)
                    
                    switch selectedTab {
                    case .vehicles:
                        VehiclesView(viewModel: vehiclesViewModel)
                    case .maintenance:
                        MaintenanceView(viewModel: maintenanceViewModel)
                    }
                    
                    Spacer(minLength: 0)
                }
            }
            .navigationTitle(selectedTab.rawValue)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        switch selectedTab {
                        case .vehicles:
                            isShowingAddVehicle = true
                        case .maintenance:
                            isShowingAddMaintenance = true
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(themeModel.textPrimary)
                            .frame(width: 34, height: 34)
//                            .background(themeModel.surfaceTertiary)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $isShowingAddVehicle) {
                AddVehicleView(viewModel: vehiclesViewModel)
            }
            .sheet(isPresented: $isShowingAddMaintenance) {
                AddMaintenanceView(viewModel: maintenanceViewModel)
            }
        }
    }
}

#Preview {
    FleetView()
}
