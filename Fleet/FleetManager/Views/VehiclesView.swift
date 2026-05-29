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

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.teal.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: "truck.box.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.teal)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(vehicle.make ?? "Unknown") \(vehicle.model ?? "")")
                    .font(.headline)
                    .foregroundColor(Color.primary)

                Text(vehicle.licensePlate ?? "No License Plate")
                    .font(.subheadline)
                    .foregroundColor(Color.secondary)
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