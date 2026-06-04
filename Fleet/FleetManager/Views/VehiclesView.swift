import SwiftUI

struct VehiclesView: View {
    var viewModel: VehiclesViewModel
    @State private var showingESG = false

    var body: some View {
        List {
            Section {
                Button(action: { showingESG = true }) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 50, height: 50)
                            Image(systemName: "leaf.arrow.circlepath")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Color.green)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ESG Compliance")
                                .font(.headline)
                                .foregroundStyle(Color.primary)
                            Text("View fleet carbon footprint & reports")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
            
            Section("All Vehicles") {
                ForEach(viewModel.vehicles) { vehicle in
                    NavigationLink(value: vehicle) {
                        VehicleRowView(
                            vehicle: vehicle,
                            statusText: viewModel.getVehicleStatusText(for: vehicle),
                            statusColor: viewModel.getVehicleStatusColor(for: vehicle)
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .sheet(isPresented: $showingESG) {
            NavigationStack {
                ESGComplianceDashboardView(
                    trips: viewModel.trips,
                    vehicles: viewModel.vehicles,
                    fuelLogs: viewModel.fuelLogs
                )
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") { showingESG = false }
                    }
                }
            }
        }
    }
}

struct VehicleRowView: View {
    let vehicle: Vehicle
    let statusText: String
    let statusColor: Color

    var vehicleIcon: String {
        guard let type = vehicle.vehicleType else { return "truck.box" }
        switch type {
        case .twoWheeler:   return "scooter"
        case .threeWheeler: return "car.2"
        case .car:          return "car"
        case .truck:        return "truck.box"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.teal.opacity(0.1))
                    .frame(width: 46, height: 46)
                Image(systemName: vehicleIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.teal)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("\(vehicle.make ?? "Unknown") \(vehicle.model ?? "")")
                    .font(.headline)
                Text(vehicle.licensePlate ?? "No Plate")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            StatusBadge(text: statusText, color: statusColor)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        VehiclesView(viewModel: VehiclesViewModel())
    }
}
