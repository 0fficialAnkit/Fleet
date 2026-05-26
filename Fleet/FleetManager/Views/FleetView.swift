import SwiftUI

enum FleetTab: String, CaseIterable {
    case drivers = "Drivers"
    case maintenance = "Maintenance Staff"
}

struct FleetView: View {
    @State private var selectedTab: FleetTab = .drivers

    @State private var employeesViewModel = EmployeesViewModel()

    @State private var isShowingAddEmployee = false
    @State private var navigationPath = NavigationPath()

    init() {
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(Color.blue)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor(Color.secondary)], for: .normal)
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    Picker("Fleet Section", selection: $selectedTab) {
                        ForEach(FleetTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)

                    switch selectedTab {
                    case .drivers:
                        EmployeesView(viewModel: employeesViewModel, roleFilter: "driver")
                    case .maintenance:
                        EmployeesView(viewModel: employeesViewModel, roleFilter: "maintenance")
                    }

                    Spacer(minLength: 0)
                }
            }
            .navigationTitle(selectedTab.rawValue)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        isShowingAddEmployee = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color.primary)
                            .frame(width: 38, height: 38)
//                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $isShowingAddEmployee) {
                AddEmployeeView(
                    viewModel: employeesViewModel,
                    roleName: selectedTab == .drivers ? "driver" : "maintenance"
                )
            }

            .task {
                await employeesViewModel.loadData()
                employeesViewModel.setupRealtime()
            }
        }
    }
}

#Preview {
    FleetView()
}