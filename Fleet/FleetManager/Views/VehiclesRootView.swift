import SwiftUI

struct VehiclesRootView: View {
    @Binding var path: NavigationPath
    @State private var vehiclesViewModel = VehiclesViewModel.shared
    @State private var isShowingAddVehicle = false

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
                }
                .buttonStyle(.plain)
            }
        }
        .navigationDestination(for: Vehicle.self) { vehicle in
            VehicleDetailView(vehicle: vehicle, viewModel: vehiclesViewModel)
        }
        .sheet(isPresented: $isShowingAddVehicle) {
            AddVehicleView(viewModel: vehiclesViewModel) { newVehicle in
                path.append(newVehicle)
            }
        }
        .task {
            await vehiclesViewModel.loadData()
            vehiclesViewModel.setupRealtime()
        }
    }
}

#Preview {
    @Previewable @State var path = NavigationPath()
    return NavigationStack(path: $path) {
        VehiclesRootView(path: $path)
    }
}
