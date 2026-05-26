import SwiftUI

struct VehiclesView: View {
    var viewModel: VehiclesViewModel
    
    var body: some View {
        Group {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(viewModel.vehicles) { vehicle in
                            NavigationLink(value: vehicle) {
                                VehicleRowView(
                                    vehicle: vehicle,
                                    statusColor: viewModel.getStatusColor(vehicle.status)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
                }
            }
            }
        }
    }


struct VehicleRowView: View {
    let vehicle: Vehicle
    let statusColor: Color
    
    var body: some View {
        
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "truck.box.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(vehicle.make ?? "Unknown") \(vehicle.model ?? "")")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.primary)
                    
                    Text(vehicle.licensePlate ?? "No License Plate")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(Color.secondary)
                }
                
                Spacer()
                
                StatusBadge(text: vehicle.status?.rawValue.capitalized ?? "Unknown", color: statusColor)
            }
            .padding(16)
            .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
    }
}

#Preview {
    NavigationStack {
        VehiclesView(viewModel: VehiclesViewModel())
    }
}
