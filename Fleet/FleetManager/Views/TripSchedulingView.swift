import SwiftUI
import MapKit

struct TripSchedulingView: View {
    @Environment(\.dismiss) private var dismiss
    var orderType: OrderType
    var selectedVehicle: Vehicle
    var selectedDriver: Profile
    var viewModel: OrdersViewModel
    @Binding var selectedOrderType: OrderType?

    @State private var startTime = Date()
    @State private var pickupLocation: SelectedLocation?
    @State private var dropoffLocation: SelectedLocation?
    @State private var showingPickupSearch = false
    @State private var showingDropoffSearch = false
    @State private var isSaving = false

    // MARK: - Validation

    private var canSave: Bool {
        pickupLocation != nil && dropoffLocation != nil
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // ── Order Summary ──────────────────────────────────
                    cardSection(title: "Order Summary") {
                        SummaryRow(title: "Order Type",
                                   value: orderType.displayName,
                                   icon: "shippingbox.fill")
                        divider
                        SummaryRow(title: "Vehicle",
                                   value: "\(selectedVehicle.make ?? "") \(selectedVehicle.model ?? "") (\(selectedVehicle.licensePlate ?? ""))",
                                   icon: "car.fill")
                        divider
                        SummaryRow(title: "Driver",
                                   value: selectedDriver.fullName,
                                   icon: "person.crop.circle.fill")
                    }

                    // ── Route ──────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Route")
                            .padding(.horizontal, 16)

                        VStack(alignment: .leading, spacing: 0) {

                            // Pickup
                            locationRow(
                                icon: "circle.fill",
                                iconColor: Color.green,
                                label: "Pickup / Origin",
                                value: pickupLocation?.title ?? "Search for pickup location",
                                subtitle: pickupLocation?.subtitle,
                                placeholder: pickupLocation == nil
                            ) {
                                showingPickupSearch = true
                            }

                            // Connector line
                            Rectangle()
                                .fill(Color(.separator))
                                .frame(width: 2, height: 28)
                                .padding(.leading, 16 + 20)

                            // Drop-off
                            locationRow(
                                icon: "mappin.circle.fill",
                                iconColor: Color.red,
                                label: "Drop-off / Destination",
                                value: dropoffLocation?.title ?? "Search for drop-off location",
                                subtitle: dropoffLocation?.subtitle,
                                placeholder: dropoffLocation == nil
                            ) {
                                showingDropoffSearch = true
                            }
                        }
                        .padding(16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                        )

                        .padding(.horizontal, 16)
                    }

                    // ── Mini Map Preview ───────────────────────────────
                    if pickupLocation != nil || dropoffLocation != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Route Preview")
                                .padding(.horizontal, 16)

                            TripRouteMapView(
                                startAddress: pickupLocation?.fullAddress,
                                endAddress: dropoffLocation?.fullAddress
                            )
                            .padding(.horizontal, 16)
                        }
                    }

                    // ── Date & Time ────────────────────────────────────
                    cardSection(title: "Schedule Date & Time") {
                        DatePicker("Start Time", selection: $startTime, in: Date()...)
                            .datePickerStyle(.graphical)
                            .tint(Color.teal)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Schedule Trip")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if isSaving {
                    ProgressView()
                        .tint(Color.teal)
                } else {
                    Button("Save") {
                        Task { await save() }
                    }
                    .foregroundStyle(canSave ? Color.teal : Color(.quaternaryLabel))
                    .bold()
                    .disabled(!canSave)
                }
            }
        }
        .sheet(isPresented: $showingPickupSearch) {
            LocationSearchView(prompt: "Pickup Location") { location in
                pickupLocation = location
            }
        }
        .sheet(isPresented: $showingDropoffSearch) {
            LocationSearchView(prompt: "Drop-off Location") { location in
                dropoffLocation = location
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

    // MARK: - Save

    private func save() async {
        guard let pickup = pickupLocation, let dropoff = dropoffLocation else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            // 1. Create a Route record with real addresses
            let route = Route(
                id: UUID(),
                routeName: "\(pickup.title) → \(dropoff.title)",
                startLocation: pickup.fullAddress,
                endLocation: dropoff.fullAddress
            )
            try await RouteService.createRoute(route)

            // 2. Create the Trip linked to the new route
            try await viewModel.addTrip(
                vehicleId: selectedVehicle.id,
                driverId: selectedDriver.id,
                routeId: route.id,
                startTime: startTime,
                orderType: orderType
            )

            // 3. Dismiss the entire sheet flow
            selectedOrderType = nil
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private var divider: some View {
        Divider().background(Color(.separator))
    }

    @ViewBuilder
    private func cardSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: title)
                .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 16) {
                content()
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )

            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func locationRow(
        icon: String,
        iconColor: Color,
        label: String,
        value: String,
        subtitle: String?,
        placeholder: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: placeholder ? 12 : 18))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)
                    Text(value)
                        .font(.body.weight(.medium))
                        .foregroundStyle(placeholder ? Color(.quaternaryLabel) : Color.primary)
                        .lineLimit(1)
                    if let sub = subtitle, !sub.isEmpty {
                        Text(sub)
                            .font(.footnote)
                            .foregroundStyle(Color.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: placeholder ? "plus.circle.fill" : "pencil.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.teal)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

struct SummaryRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.teal)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Color(.tertiaryLabel))
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.primary)
            }
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        TripSchedulingView(
            orderType: .bulkOrderShip,
            selectedVehicle: Vehicle(
                id: UUID(),
                make: "Ford",
                model: "Transit",
                year: 2024,
                vin: "12345",
                licensePlate: "FL-99-TR",
                tankCapacity: 80.0,
                mileage: 12.4,
                purchaseDate: Date(),
                assignedDriverId: nil,
                status: .active
            ),
            selectedDriver: Profile(
                id: UUID(),
                fullName: "John Doe",
                email: "john@example.com",
                phone: "1234567890",
                licenseNumber: "LIC12345",
                role: "driver",
                status: "active",
                createdAt: Date()
            ),
            viewModel: OrdersViewModel(),
            selectedOrderType: .constant(.bulkOrderShip)
        )
    }
}