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
                        .fill(themeModel.accent.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "truck.box.fill")
                        .font(.system(size: 20))
                        .foregroundColor(themeModel.accent)
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
                
                StatusBadge(text: vehicle.status?.rawValue.capitalized ?? "Unknown", color: statusColor)
            }
            .padding(themeModel.spacingMD)
            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
    }
}

#Preview {
    NavigationStack {
        VehiclesView(viewModel: VehiclesViewModel())
    }
}
