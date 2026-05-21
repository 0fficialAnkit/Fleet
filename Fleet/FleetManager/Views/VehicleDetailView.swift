import SwiftUI

struct VehicleDetailView: View {
    let vehicle: Vehicle
    let viewModel: VehiclesViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingEditSheet = false
    
    var currentVehicle: Vehicle {
        viewModel.vehicles.first { $0.id == vehicle.id } ?? vehicle
    }
    
    var driverName: String {
        viewModel.getDriver(for: currentVehicle.assignedDriverId)?.fullName ?? "Unassigned"
    }
    
    var pastTrips: [Trip] {
        viewModel.getPastTrips(for: currentVehicle.id)
    }
    
    var body: some View {
        ZStack {
            themeModel.backgroundPrimary.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: themeModel.spacingLG) {
                    // Header Section
                    VStack(spacing: themeModel.spacingSM) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 60))
                            .foregroundColor(themeModel.info)
                            .padding(.bottom, 8)
                        
                        Text("\(currentVehicle.make ?? "Unknown") \(currentVehicle.model ?? "")")
                            .font(themeModel.largeTitle(28))
                            .foregroundColor(themeModel.textPrimary)
                        
                        Text(currentVehicle.licensePlate ?? "No License Plate")
                            .font(themeModel.bodyMedium(16))
                            .foregroundColor(themeModel.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(themeModel.surfaceTertiary)
                            .clipShape(Capsule())
                    }
                    .padding(.top, themeModel.spacingXL)
                    
                    // Vehicle Info Card
                    VStack(spacing: 0) {
                        DetailInfoRow(title: "Manufacturer", value: currentVehicle.make ?? "N/A")
                        Divider().background(themeModel.divider)
                        DetailInfoRow(title: "Model", value: currentVehicle.model ?? "N/A")
                        Divider().background(themeModel.divider)
                        DetailInfoRow(title: "Year", value: currentVehicle.year != nil ? String(currentVehicle.year!) : "N/A")
                        Divider().background(themeModel.divider)
                        DetailInfoRow(title: "Tank Capacity", value: currentVehicle.tankCapacity != nil ? "\(String(format: "%.1f", currentVehicle.tankCapacity!)) L" : "N/A")
                        Divider().background(themeModel.divider)
                        DetailInfoRow(title: "Mileage", value: currentVehicle.mileage != nil ? "\(String(format: "%.1f", currentVehicle.mileage!)) km/l" : "N/A")
                        Divider().background(themeModel.divider)
                        DetailInfoRow(title: "Purchase Date", value: currentVehicle.purchaseDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")
                    }
                    .padding(themeModel.spacingMD)
                    .background(themeModel.backgroundElevated)
                    .cornerRadius(themeModel.radiusLG)
                    .padding(.horizontal, themeModel.spacingMD)
                    
                    // Assigned Driver Card
                    VStack(alignment: .leading, spacing: themeModel.spacingSM) {
                        Text("Current Driver")
                            .font(themeModel.headline(18))
                            .foregroundColor(themeModel.textPrimary)
                            .padding(.horizontal, themeModel.spacingMD)
                        
                        HStack(spacing: themeModel.spacingMD) {
                            Circle()
                                .fill(themeModel.surfaceTertiary)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(themeModel.textSecondary)
                                )
                            
                            Text(driverName)
                                .font(themeModel.body(16))
                                .foregroundColor(themeModel.textPrimary)
                            
                            Spacer()
                        }
                        .padding(themeModel.spacingMD)
                        .background(themeModel.backgroundElevated)
                        .cornerRadius(themeModel.radiusLG)
                        .padding(.horizontal, themeModel.spacingMD)
                    }
                    
                    // Past Trips History
                    VStack(alignment: .leading, spacing: themeModel.spacingSM) {
                        Text("Past Trips")
                            .font(themeModel.headline(18))
                            .foregroundColor(themeModel.textPrimary)
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
        .toolbarBackground(themeModel.backgroundPrimary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: {
                        isShowingEditSheet = true
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: {
                        viewModel.deleteVehicle(currentVehicle)
                        dismiss()
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(themeModel.textPrimary)
                        .padding(8)
                }
            }
        }
        .sheet(isPresented: $isShowingEditSheet) {
            EditVehicleView(vehicle: currentVehicle, viewModel: viewModel)
        }
    }
}

struct DetailInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(themeModel.bodyMedium(16))
                .foregroundColor(themeModel.textSecondary)
            Spacer()
            Text(value)
                .font(themeModel.body(16))
                .foregroundColor(themeModel.textPrimary)
        }
        .padding(.vertical, 12)
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
        .background(themeModel.backgroundElevated)
        .cornerRadius(themeModel.radiusLG)
    }
}

#Preview {
    NavigationStack {
        VehicleDetailView(vehicle: MockData.vehicles.first!, viewModel: VehiclesViewModel())
            .preferredColorScheme(.dark)
    }
}
