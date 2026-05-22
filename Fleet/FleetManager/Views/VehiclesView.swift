import SwiftUI

struct VehiclesView: View {
    @State private var viewModel = VehiclesViewModel()
    
    var body: some View {
        NavigationStack {
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
            .navigationTitle("Vehicles")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        // Add vehicle action
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(themeModel.textPrimary)
                            .frame(width: 38, height: 38)
                            .glassEffect(in: Circle())
                    }
                    .buttonStyle(.plain)
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
    VehiclesView()
}
