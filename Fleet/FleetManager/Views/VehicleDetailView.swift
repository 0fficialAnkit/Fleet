import SwiftUI

struct VehicleDetailView: View {
    let vehicle: Vehicle
    let viewModel: VehiclesViewModel
    
    var driverName: String {
        viewModel.getDriver(for: vehicle.assignedDriverId)?.fullName ?? "Unassigned"
    }
    
    var pastTrips: [Trip] {
        viewModel.getPastTrips(for: vehicle.id)
    }
    
    var body: some View {
        ZStack {
            themeModel.backgroundPrimary.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: themeModel.spacingLG) {
                    // Header Section
                    VStack(spacing: themeModel.spacingSM) {
                        Image(systemName: "truck.box.fill")
                            .font(.system(size: 60))
                            .foregroundColor(themeModel.accent)
                            .padding(.bottom, 8)
                        
                        Text("\(vehicle.make ?? "Unknown") \(vehicle.model ?? "")")
                            .font(themeModel.largeTitle(28))
                            .foregroundColor(themeModel.textPrimary)
                        
                        StatusBadge(text: vehicle.licensePlate ?? "No License Plate", color: themeModel.accent)
                    }
                    .padding(.top, themeModel.spacingXL)
                    
                    // Vehicle Info Card
                    
                        VStack(spacing: 0) {
                            InfoRow(icon: "building.2", label: "Manufacturer", value: vehicle.make ?? "N/A")
                            Divider().background(themeModel.divider)
                            InfoRow(icon: "tag", label: "Model", value: vehicle.model ?? "N/A")
                            Divider().background(themeModel.divider)
                            InfoRow(icon: "calendar", label: "Year", value: vehicle.year != nil ? String(vehicle.year!) : "N/A")
                            Divider().background(themeModel.divider)
                            InfoRow(icon: "fuelpump", label: "Tank Capacity", value: vehicle.tankCapacity != nil ? "\(String(format: "%.1f", vehicle.tankCapacity!)) L" : "N/A")
                            Divider().background(themeModel.divider)
                            InfoRow(icon: "gauge.open.with.lines.needle.33percent", label: "Mileage", value: vehicle.mileage != nil ? "\(String(format: "%.1f", vehicle.mileage!)) km/l" : "N/A")
                            Divider().background(themeModel.divider)
                            InfoRow(icon: "creditcard", label: "Purchase Date", value: vehicle.purchaseDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")
                        }
                        .padding(themeModel.spacingMD)
                        .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                        )
                        .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
                    .padding(.horizontal, themeModel.spacingMD)
                    
                    // Assigned Driver Card
                    VStack(alignment: .leading, spacing: themeModel.spacingSM) {
                        SectionHeader(title: "Current Driver")
                            .padding(.horizontal, themeModel.spacingMD)
                        
                        
                            HStack(spacing: themeModel.spacingMD) {
                                Circle()
                                    .fill(themeModel.accent.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "person.crop.circle.fill")
                                            .foregroundColor(themeModel.accent)
                                            .font(.system(size: 20))
                                    )
                                
                                Text(driverName)
                                    .font(themeModel.body(16))
                                    .foregroundColor(themeModel.textPrimary)
                                
                                Spacer()
                            }
                            .padding(themeModel.spacingMD)
                            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                            )
                            .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
                        .padding(.horizontal, themeModel.spacingMD)
                    }
                    
                    // Past Trips History
                    VStack(alignment: .leading, spacing: themeModel.spacingSM) {
                        SectionHeader(title: "Past Trips")
                            .padding(.horizontal, themeModel.spacingMD)
                        
                        if pastTrips.isEmpty {
                            Text("No past trips recorded.")
                                .font(themeModel.bodyMedium(14))
                                .foregroundColor(themeModel.textSecondary)
                                .padding(.horizontal, themeModel.spacingMD)
                        } else {
                            ForEach(pastTrips) { trip in
                                TripHistoryRow(trip: trip, viewModel: viewModel)
                            }
                            .padding(.horizontal, themeModel.spacingMD)
                        }
                    }
                }
                .padding(.bottom, themeModel.spacingXXL)
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TripHistoryRow: View {
    let trip: Trip
    let viewModel: VehiclesViewModel
    
    var driverName: String {
        viewModel.getDriver(for: trip.driverId)?.fullName ?? "Unknown Driver"
    }
    
    var body: some View {
        
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "map.fill")
                        .foregroundColor(themeModel.info)
                    Text("Distance: \(String(format: "%.1f", trip.distance ?? 0)) km")
                        .font(themeModel.headline(16))
                        .foregroundColor(themeModel.textPrimary)
                    Spacer()
                    Text(trip.endTime?.formatted(date: .abbreviated, time: .shortened) ?? "")
                        .font(themeModel.caption(12))
                        .foregroundColor(themeModel.textTertiary)
                }
                
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(themeModel.textSecondary)
                        .font(.system(size: 14))
                    Text("Driver: \(driverName)")
                        .font(themeModel.body(14))
                        .foregroundColor(themeModel.textSecondary)
                }
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
        VehicleDetailView(vehicle: MockData.vehicles.first!, viewModel: VehiclesViewModel())
    }
}
