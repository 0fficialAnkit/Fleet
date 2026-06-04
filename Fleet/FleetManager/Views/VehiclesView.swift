import SwiftUI

struct VehiclesView: View {
    var viewModel: VehiclesViewModel

    var body: some View {
        List(viewModel.vehicles) { vehicle in
            NavigationLink(value: vehicle) {
                VehicleRowView(
                    vehicle: vehicle,
                    statusText: viewModel.getVehicleStatusText(for: vehicle),
                    statusColor: viewModel.getVehicleStatusColor(for: vehicle)
                )
            }
        }
        .listStyle(.insetGrouped)
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
