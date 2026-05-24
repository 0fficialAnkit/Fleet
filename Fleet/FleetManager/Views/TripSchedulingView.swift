import SwiftUI

struct TripSchedulingView: View {
    @Environment(\.dismiss) private var dismiss
    var orderType: OrderType
    var selectedVehicle: Vehicle
    var selectedDriver: Profile
    var viewModel: OrdersViewModel
    @Binding var selectedOrderType: OrderType?
    
    @State private var startTime = Date()
    @State private var selectedRouteId: UUID?
    
    var body: some View {
        ZStack {
            themeModel.backgroundPrimary.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: themeModel.spacingLG) {
                    
                    // Order Summary Card
                    VStack(alignment: .leading, spacing: themeModel.spacingSM) {
                        SectionHeader(title: "Order Summary")
                            .padding(.horizontal, themeModel.spacingMD)
                        
                        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
                            SummaryRow(title: "Order Type", value: orderType.displayName, icon: "shippingbox.fill")
                            Divider().background(themeModel.divider)
                            SummaryRow(title: "Vehicle", value: "\(selectedVehicle.make ?? "") \(selectedVehicle.model ?? "") (\(selectedVehicle.licensePlate ?? ""))", icon: "car.fill")
                            Divider().background(themeModel.divider)
                            SummaryRow(title: "Driver", value: selectedDriver.fullName, icon: "person.crop.circle.fill")
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
                    
                    // Route Selection
                    if !viewModel.routes.isEmpty {
                        VStack(alignment: .leading, spacing: themeModel.spacingSM) {
                            SectionHeader(title: "Select Route")
                                .padding(.horizontal, themeModel.spacingMD)
                            
                            VStack(spacing: themeModel.spacingMD) {
                                Picker("Route", selection: $selectedRouteId) {
                                    Text("Select a route").tag(UUID?.none)
                                    ForEach(viewModel.routes) { route in
                                        Text(route.routeName ?? "Unknown Route")
                                            .tag(UUID?.some(route.id))
                                    }
                                }
                                .foregroundColor(themeModel.textPrimary)
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
                    }
                    
                    // Date & Time Picker Card
                    VStack(alignment: .leading, spacing: themeModel.spacingSM) {
                        SectionHeader(title: "Schedule Date & Time")
                            .padding(.horizontal, themeModel.spacingMD)
                        
                        VStack(spacing: themeModel.spacingMD) {
                            DatePicker("Start Time", selection: $startTime, in: Date()...)
                                .datePickerStyle(.graphical)
                                .tint(themeModel.accent)
                                .padding(.vertical, 8)
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
                    
                }
                .padding(.vertical, themeModel.spacingMD)
            }
        }
        .navigationTitle("Schedule Trip")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Default to the first route
            if selectedRouteId == nil {
                selectedRouteId = viewModel.routes.first?.id
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        do {
                            try await viewModel.addTrip(
                                vehicleId: selectedVehicle.id,
                                driverId: selectedDriver.id,
                                routeId: selectedRouteId,
                                startTime: startTime,
                                orderType: orderType
                            )
                            selectedOrderType = nil // Dismisses the entire sheet flow directly to order list
                        } catch {
                            viewModel.errorMessage = error.localizedDescription
                        }
                    }
                }
                .foregroundColor(themeModel.accent)
                .bold()
            }
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }
}

struct SummaryRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(themeModel.accent)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(themeModel.caption(12))
                    .foregroundColor(themeModel.textTertiary)
                Text(value)
                    .font(themeModel.bodyMedium(14))
                    .foregroundColor(themeModel.textPrimary)
            }
            Spacer()
        }
    }
}
