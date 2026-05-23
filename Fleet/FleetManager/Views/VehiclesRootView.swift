import SwiftUI

struct VehiclesRootView: View {
    @State private var vehiclesViewModel = VehiclesViewModel()
    @State private var isShowingAddVehicle = false

    var body: some View {
        ZStack {
            themeModel.backgroundPrimary.ignoresSafeArea()
            VehiclesView(viewModel: vehiclesViewModel)
        }
        .navigationTitle("Vehicles")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { isShowingAddVehicle = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(themeModel.textPrimary)
                        .frame(width: 38, height: 38)
//                        .glassEffect(in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $isShowingAddVehicle) {
            AddVehicleView(viewModel: vehiclesViewModel)
        }
        .task {
            await vehiclesViewModel.loadData()
            vehiclesViewModel.setupRealtime()
        }
    }
}

#Preview {
    VehiclesRootView()
}
