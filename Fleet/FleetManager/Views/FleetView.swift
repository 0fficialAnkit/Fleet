import SwiftUI
internal import Auth

struct FleetView: View {
    @State private var viewModel = EmployeesViewModel()
    @State private var isAddingEmployee = false
    @Environment(AuthViewModel.self) private var authViewModel
    
    // Filter and Sort state
    @State private var selectedRole: String = "driver"
    @State private var sortOption: EmployeeSortOption = .dateAddedLatest

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Native segmented control
                Picker("Role", selection: $selectedRole) {
                    Text("Drivers").tag("driver")
                    Text("Maintenance Staff").tag("maintenance")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemGroupedBackground))

                EmployeesView(viewModel: viewModel, roleFilter: selectedRole, sortOption: sortOption)
            }
            .navigationTitle("Fleet")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        isAddingEmployee = true
                    }) {
                        Image(systemName: "plus")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $isAddingEmployee) {
                AddEmployeeView(viewModel: viewModel, initialRole: selectedRole)
            }
            .task {
                // adminId is set via onChange below
            }
            .onChange(of: authViewModel.currentUser?.id, initial: true) { _, _ in
                guard let adminId = authViewModel.currentUserId else { return }
                viewModel.adminId = adminId
                Task {
                    await viewModel.loadData()
                    viewModel.setupRealtime()
                }
            }
        }
    }
}

#Preview {
    FleetView()
}