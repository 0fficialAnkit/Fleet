import SwiftUI

enum EmployeeTab: String, CaseIterable {
    case drivers = "Drivers"
    case maintenance = "Maintenance Staff"
}

struct EmployeeMainView: View {
    @State private var selectedTab: EmployeeTab = .drivers
    @State private var employeesViewModel = EmployeesViewModel()
    @State private var isShowingAddEmployee = false
    
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
                    Picker("Employee Section", selection: $selectedTab) {
                        ForEach(EmployeeTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, themeModel.spacingMD)
                    .padding(.vertical, themeModel.spacingMD)
                    
                    switch selectedTab {
                    case .drivers:
                        EmployeesView(viewModel: employeesViewModel, filterRole: "driver")
                    case .maintenance:
                        EmployeesView(viewModel: employeesViewModel, filterRole: "maintenance")
                    }
                    
                    Spacer(minLength: 0)
                }
            }
            .navigationTitle("Employees")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        isShowingAddEmployee = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(themeModel.textPrimary)
                            .frame(width: 38, height: 38)
                            .background(themeModel.surfaceTertiary)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $isShowingAddEmployee) {
                AddEmployeeView(
                    viewModel: employeesViewModel,
                    preselectedRoleName: selectedTab == .drivers ? "driver" : "maintenance"
                )
            }
        }
    }
}

#Preview {
    EmployeeMainView()
}
