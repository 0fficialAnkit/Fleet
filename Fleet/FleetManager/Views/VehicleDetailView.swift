import SwiftUI

struct VehicleDetailView: View {
    let vehicle: Vehicle
    let viewModel: VehiclesViewModel
    
    @State private var isShowingEdit = false
    @Environment(\.dismiss) private var dismiss
    
    var driverName: String {
        viewModel.getDriver(for: vehicle.assignedDriverId)?.fullName ?? "Unassigned"
    }
    
    var pastTrips: [Trip] {
        viewModel.getPastTrips(for: vehicle.id)
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 8) {
                        Image(systemName: "truck.box.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color.blue)
                            .padding(.bottom, 8)
                        
                        Text("\(vehicle.make ?? "Unknown") \(vehicle.model ?? "")")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Color.primary)
                        
                        StatusBadge(text: vehicle.licensePlate ?? "No License Plate", color: Color.blue)
                    }
                    .padding(.top, 32)
                    
                    // Vehicle Info Card
                    
                        VStack(spacing: 0) {
                            InfoRow(icon: "building.2", label: "Manufacturer", value: vehicle.make ?? "N/A")
                            Divider().background(Color(UIColor.separator))
                            InfoRow(icon: "tag", label: "Model", value: vehicle.model ?? "N/A")
                            Divider().background(Color(UIColor.separator))
                            InfoRow(icon: "calendar", label: "Year", value: vehicle.year != nil ? String(vehicle.year!) : "N/A")
                            Divider().background(Color(UIColor.separator))
                            InfoRow(icon: "fuelpump", label: "Tank Capacity", value: vehicle.tankCapacity != nil ? "\(String(format: "%.1f", vehicle.tankCapacity!)) L" : "N/A")
                            Divider().background(Color(UIColor.separator))
                            InfoRow(icon: "gauge.open.with.lines.needle.33percent", label: "Mileage", value: vehicle.mileage != nil ? "\(String(format: "%.1f", vehicle.mileage!)) km/l" : "N/A")
                            Divider().background(Color(UIColor.separator))
                            InfoRow(icon: "creditcard", label: "Purchase Date", value: vehicle.purchaseDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")
                        }
                        .padding(16)
                        .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
                    .padding(.horizontal, 16)
                    
                    // Assigned Driver Card
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Current Driver")
                            .padding(.horizontal, 16)
                        
                        
                            HStack(spacing: 16) {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "person.crop.circle.fill")
                                            .foregroundColor(Color.blue)
                                            .font(.system(size: 20))
                                    )
                                
                                Text(driverName)
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(Color.primary)
                                
                                Spacer()
                            }
                            .padding(16)
                            .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
                        .padding(.horizontal, 16)
                    }
                    
                    // Past Trips History
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Past Trips")
                            .padding(.horizontal, 16)
                        
                        if pastTrips.isEmpty {
                            Text("No past trips recorded.")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(Color.secondary)
                                .padding(.horizontal, 16)
                        } else {
                            ForEach(pastTrips) { trip in
                                TripHistoryRow(trip: trip, viewModel: viewModel)
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: {
                        isShowingEdit = true
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: {
                        Task {
                            do {
                                try await viewModel.deleteVehicle(vehicle)
                                dismiss()
                            } catch {
                                viewModel.errorMessage = error.localizedDescription
                            }
                        }
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color.primary)
                }
            }
        }
        .sheet(isPresented: $isShowingEdit) {
            EditVehicleView(viewModel: viewModel, vehicle: vehicle)
        }
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
                        .foregroundColor(Color.blue)
                    Text("Distance: \(String(format: "%.1f", trip.distance ?? 0)) km")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.primary)
                    Spacer()
                    Text(trip.endTime?.formatted(date: .abbreviated, time: .shortened) ?? "")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
                
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(Color.secondary)
                        .font(.system(size: 14))
                    Text("Driver: \(driverName)")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(Color.secondary)
                }
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
        VehicleDetailView(
            vehicle: Vehicle(
                id: UUID(),
                make: "Ford",
                model: "Transit",
                year: 2024,
                vin: "123456789",
                licensePlate: "FL-99-TR",
                tankCapacity: 80.0,
                mileage: 12.4,
                purchaseDate: Date(),
                assignedDriverId: nil,
                status: .active
            ),
            viewModel: VehiclesViewModel()
        )
    }
}
