import SwiftUI

struct VehicleSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    var orderType: OrderType
    var viewModel: OrdersViewModel
    @Binding var selectedOrderType: OrderType?

    var availableVehicles: [Vehicle] {
        viewModel.availableVehicles(for: orderType)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {

                        if availableVehicles.isEmpty {
                            Text("No active vehicles match this order type.")
                                .font(.body)
                                .foregroundColor(Color.secondary)
                                .padding(.top, 40)
                        } else {
                            ForEach(availableVehicles) { vehicle in
                                VehicleSelectionRow(vehicle: vehicle, orderType: orderType, viewModel: viewModel, selectedOrderType: $selectedOrderType)
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Select Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(.systemGroupedBackground), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.teal)
                }
            }
            .onChange(of: selectedOrderType) { _, newValue in
                if newValue == nil {
                    dismiss()
                }
            }
        }
    }
}

struct VehicleSelectionRow: View {
    let vehicle: Vehicle
    var orderType: OrderType
    var viewModel: OrdersViewModel
    @Binding var selectedOrderType: OrderType?

    var body: some View {
        NavigationLink(destination: DriverSelectionView(orderType: orderType, selectedVehicle: vehicle, viewModel: viewModel, selectedOrderType: $selectedOrderType)) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(vehicle.make ?? "") \(vehicle.model ?? "")")
                        .font(.body.bold())
                        .foregroundColor(Color.primary)

                    HStack(spacing: 8) {
                        StatusBadge(text: vehicle.licensePlate ?? "No Plate", color: Color.teal)

                        if vehicle.assignedDriverId == nil {
                            StatusBadge(text: "No Driver", color: Color.yellow)
                        }
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(.tertiaryLabel))
                    .font(.system(size: 14, weight: .bold))
            }
            .contentShape(Rectangle())
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )

        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VehicleSelectionView(orderType: .pickUpAndDrop, viewModel: OrdersViewModel(), selectedOrderType: .constant(.pickUpAndDrop))
}