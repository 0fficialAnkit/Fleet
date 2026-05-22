import SwiftUI

struct VehiclesView: View {
    var viewModel: VehiclesViewModel
    
    var body: some View {
        Group {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: themeModel.spacingMD) {
                        ForEach(viewModel.vehicles) { vehicle in
                            NavigationLink(destination: VehicleDetailView(vehicle: vehicle, viewModel: viewModel)) {
                                VehicleRowView(
                                    vehicle: vehicle,
                                    statusColor: viewModel.getStatusColor(vehicle.status)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, themeModel.spacingMD)
                    .padding(.horizontal, themeModel.spacingMD)
                }
            }
            }
        }
    }


struct VehicleRowView: View {
    let vehicle: Vehicle
    let statusColor: Color
    
    var body: some View {
        HStack(spacing: themeModel.spacingMD) {
            ZStack {
                Circle()
                    .fill(themeModel.surfaceTertiary)
                    .frame(width: 48, height: 48)
                
                Image(systemName: "car.fill")
                    .font(.system(size: 20))
                    .foregroundColor(themeModel.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(vehicle.make ?? "Unknown") \(vehicle.model ?? "")")
                    .font(themeModel.headline(18))
                    .foregroundColor(themeModel.textPrimary)
                
                Text(vehicle.licensePlate ?? "No License Plate")
                    .font(themeModel.caption(14))
                    .foregroundColor(themeModel.textSecondary)
            }
            
            Spacer()
            
            Text(vehicle.status?.rawValue.capitalized ?? "Unknown")
                .font(themeModel.caption(12))
                .foregroundColor(statusColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(themeModel.spacingMD)
        .background(themeModel.backgroundElevated)
        .cornerRadius(themeModel.radiusLG)
    }
}

#Preview {
    NavigationStack {
        VehiclesView(viewModel: VehiclesViewModel())
    }
}
