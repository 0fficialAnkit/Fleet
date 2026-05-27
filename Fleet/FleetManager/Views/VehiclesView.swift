import SwiftUI

struct VehiclesView: View {
    var viewModel: VehiclesViewModel

    var body: some View {
        List(viewModel.vehicles) { vehicle in
            NavigationLink(value: vehicle) {
                VehicleRowView(
                    vehicle: vehicle,
                    statusColor: viewModel.getStatusColor(vehicle.status)
                )
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct VehicleRowView: View {
    let vehicle: Vehicle
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

            StatusBadge(text: vehicle.status?.rawValue.capitalized ?? "Unknown", color: statusColor)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        VehiclesView(viewModel: VehiclesViewModel())
    }
}