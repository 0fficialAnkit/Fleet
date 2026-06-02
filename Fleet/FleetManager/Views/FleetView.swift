import SwiftUI

struct FleetView: View {
    @State private var viewModel = EmployeesViewModel()
    @State private var isAddingEmployee = false
    
    // Filter and Sort state
    @State private var roleFilter: String? = nil
    @State private var sortOption: EmployeeSortOption = .dateAddedLatest

    var body: some View {
        NavigationStack {
            EmployeesView(viewModel: viewModel, roleFilter: roleFilter, sortOption: sortOption)
                .navigationTitle("Fleet")
                .safeAreaInset(edge: .bottom, alignment: .trailing) {
                    AddEmployeeFAB {
                        isAddingEmployee = true
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 12)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Picker("Filter by Role", selection: $roleFilter) {
                                Text("All").tag(String?.none)
                                Text("Drivers").tag(String?.some("driver"))
                                Text("Maintenance Staff").tag(String?.some("maintenance"))
                            }
                            
                            Divider()
                            
                            Menu {
                                Picker("Sort", selection: $sortOption) {
                                    Text("Date Added (Latest)").tag(EmployeeSortOption.dateAddedLatest)
                                    Text("Date Added (Oldest)").tag(EmployeeSortOption.dateAddedOldest)
                                    Text("Name (A to Z)").tag(EmployeeSortOption.nameAZ)
                                    Text("Name (Z to A)").tag(EmployeeSortOption.nameZA)
                                }
                            } label: {
                                Label("Sort By", systemImage: "arrow.up.arrow.down")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.body)
                        }
                    }
                }
                .sheet(isPresented: $isAddingEmployee) {
                    AddEmployeeView(viewModel: viewModel)
                }
                .task {
                    await viewModel.loadData()
                    viewModel.setupRealtime()
                }
        }
    }
}

// MARK: - Floating Action Button

private struct AddEmployeeFAB: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(.primary)
                .frame(width: 56, height: 56)
                // Clean liquid glass effect
                .background(.ultraThinMaterial, in: Circle())
                .shadow(color: .black.opacity(0.12), radius: 12, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add employee")
    }
}

#Preview {
    FleetView()
}