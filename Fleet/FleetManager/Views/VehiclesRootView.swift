import SwiftUI
internal import Auth   // needed for user.id from Supabase Auth module

struct VehiclesRootView: View {
    @State private var vehiclesViewModel = VehiclesViewModel()
    @State private var isShowingAddVehicle = false
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            if let error = vehiclesViewModel.errorMessage {
                ContentUnavailableView(
                    "Error Loading Data",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else {
                VehiclesView(viewModel: vehiclesViewModel)
            }
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
            AddVehicleView(viewModel: vehiclesViewModel)
        }
        .task {
            // adminId is set via onChange below
        }
        .onChange(of: authViewModel.currentUser?.id, initial: true) { _, _ in
            guard let adminId = authViewModel.currentUserId else { return }
            vehiclesViewModel.adminId = adminId
            Task {
                await vehiclesViewModel.loadData()
                vehiclesViewModel.setupRealtime()
            }
        }
    }
}

#Preview {
    VehiclesRootView()
}