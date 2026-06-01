import SwiftUI
internal import Auth

struct VehiclesRootView: View {
    @State private var vehiclesViewModel = VehiclesViewModel()
    @State private var isShowingAddVehicle = false
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            VehiclesView(viewModel: vehiclesViewModel)
        }
        .navigationTitle("Vehicles")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { isShowingAddVehicle = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color.primary)
                        .frame(width: 38, height: 38)
//                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .navigationDestination(for: Vehicle.self) { vehicle in
            VehicleDetailView(vehicle: vehicle, viewModel: vehiclesViewModel)
        }
        .sheet(isPresented: $isShowingAddVehicle) {
            AddVehicleView(viewModel: vehiclesViewModel)
        }
        .task {
            let adminId = authViewModel.currentUser?.id
            await vehiclesViewModel.loadData(adminId: adminId)
            vehiclesViewModel.setupRealtime(adminId: adminId)
        }
    }
}

#Preview {
    VehiclesRootView()
}