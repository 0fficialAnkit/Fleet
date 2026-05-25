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
                themeModel.backgroundPrimary.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: themeModel.spacingMD) {
                        
                        if availableVehicles.isEmpty {
                            Text("No active vehicles match this order type.")
                                .font(themeModel.body(16))
                                .foregroundColor(themeModel.textSecondary)
                                .padding(.top, 40)
                        } else {
                            ForEach(availableVehicles) { vehicle in
                                VehicleSelectionRow(vehicle: vehicle, orderType: orderType, viewModel: viewModel, selectedOrderType: $selectedOrderType)
                            }
                            .padding(.horizontal, themeModel.spacingMD)
                        }
                    }
                    .padding(.vertical, themeModel.spacingMD)
                }
            }
            .navigationTitle("Select Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(themeModel.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeModel.accent)
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
                        .font(themeModel.headline(16))
                        .foregroundColor(themeModel.textPrimary)
                    
                    HStack(spacing: 8) {
                        StatusBadge(text: vehicle.licensePlate ?? "No Plate", color: themeModel.accent)
                        
                        if vehicle.assignedDriverId == nil {
                            StatusBadge(text: "No Driver", color: themeModel.warning)
                        }
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(themeModel.textTertiary)
                    .font(.system(size: 14, weight: .bold))
            }
            .contentShape(Rectangle())
            .padding(themeModel.spacingMD)
            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VehicleSelectionView(orderType: .pickUpAndDrop, viewModel: OrdersViewModel(), selectedOrderType: .constant(.pickUpAndDrop))
}
