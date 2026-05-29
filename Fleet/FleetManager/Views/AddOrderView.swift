import SwiftUI
import MapKit

struct AddOrderView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: OrdersViewModel

    // MARK: - Form State
    @State private var startTime = Date()
    @State private var orderType: OrderType = .pickUpAndDrop
    @State private var pickupLocation: SelectedLocation?
    @State private var dropoffLocation: SelectedLocation?
    @State private var selectedVehicleId: UUID?
    @State private var selectedDriverId: UUID?

    // MARK: - Sheet Control
    @State private var showingPickupSearch  = false
    @State private var showingDropoffSearch = false
    @State private var isSaving = false

    // MARK: - Derived
    private var availableVehicles: [Vehicle] {
        viewModel.availableVehicles(for: orderType, at: startTime)
    }

    private var availableDrivers: [Profile] {
        viewModel.availableDrivers(at: startTime)
    }

    private var canSave: Bool {
        pickupLocation != nil &&
        dropoffLocation != nil &&
        selectedVehicleId != nil &&
        selectedDriverId != nil
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {

                // ── Schedule ──────────────────────────────────────────
                Section {
                    DatePicker(
                        "Date & Time",
                        selection: $startTime,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .tint(Color.teal)
                } header: {
                    Label("Schedule", systemImage: "calendar")
                }

                // ── Order Type ────────────────────────────────────────
                Section {
                    Picker("Type", selection: $orderType) {
                        ForEach(OrderType.allCases) { type in
                            Label(type.displayName, systemImage: orderTypeIcon(type))
                                .tag(type)
                        }
                    }
                    .tint(.primary)
                } header: {
                    Label("Order Type", systemImage: "shippingbox.fill")
                }

                // ── Route ─────────────────────────────────────────────
                Section {
                    // Pickup row
                    Button { showingPickupSearch = true } label: {
                        locationRowLabel(
                            icon: "circle.fill",
                            iconColor: .green,
                            caption: "Pickup / Origin",
                            value: pickupLocation?.title,
                            subtitle: pickupLocation?.subtitle,
                            isSet: pickupLocation != nil
                        )
                    }
                    .foregroundStyle(.primary)

                    // Drop-off row
                    Button { showingDropoffSearch = true } label: {
                        locationRowLabel(
                            icon: "mappin.circle.fill",
                            iconColor: .red,
                            caption: "Drop-off / Destination",
                            value: dropoffLocation?.title,
                            subtitle: dropoffLocation?.subtitle,
                            isSet: dropoffLocation != nil
                        )
                    }
                    .foregroundStyle(.primary)
                } header: {
                    Label("Route", systemImage: "map.fill")
                }

                // ── Assignment ────────────────────────────────────────
                Section {
                    // Vehicle picker
                    if availableVehicles.isEmpty {
                        LabeledContent {
                            Text("No vehicles available")
                                .foregroundStyle(Color.secondary)
                                .font(.caption)
                        } label: {
                            Label("Vehicle", systemImage: "car.fill")
                        }
                    } else {
                        Picker(selection: $selectedVehicleId) {
                            Text("Select a vehicle").tag(UUID?.none)
                            ForEach(availableVehicles) { v in
                                Text("\(v.make ?? "Unknown") \(v.model ?? "") · \(v.licensePlate ?? "—")")
                                    .tag(v.id as UUID?)
                            }
                        } label: {
                            Label("Vehicle", systemImage: "car.fill")
                        }
                        .tint(.primary)
                    }

                    // Driver picker
                    if availableDrivers.isEmpty {
                        LabeledContent {
                            Text("No drivers available")
                                .foregroundStyle(Color.secondary)
                                .font(.caption)
                        } label: {
                            Label("Driver", systemImage: "person.crop.circle.fill")
                        }
                    } else {
                        Picker(selection: $selectedDriverId) {
                            Text("Select a driver").tag(UUID?.none)
                            ForEach(availableDrivers) { d in
                                Text(d.fullName)
                                    .tag(d.id as UUID?)
                            }
                        } label: {
                            Label("Driver", systemImage: "person.crop.circle.fill")
                        }
                        .tint(.primary)
                    }
                } header: {
                    Label("Assignment", systemImage: "person.badge.key.fill")
                } footer: {
                    if !canSave {
                        Text("Fill in all fields to save the order.")
                            .font(.caption)
                    }
                }

                // ── Route Preview ─────────────────────────────────────
                if pickupLocation != nil || dropoffLocation != nil {
                    Section {
                        TripRouteMapView(
                            startAddress: pickupLocation?.fullAddress,
                            endAddress: dropoffLocation?.fullAddress
                        )
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    } header: {
                        Label("Route Preview", systemImage: "map.fill")
                    }
                }
            }
            .navigationTitle("New Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView().tint(Color.teal)
                    } else {
                        Button("Save") {
                            Task { await save() }
                        }
                        .bold()
                        .foregroundStyle(canSave ? Color.teal : Color(.quaternaryLabel))
                        .disabled(!canSave)
                    }
                }
            }
            // Pickup search sheet
            .sheet(isPresented: $showingPickupSearch) {
                LocationSearchView(prompt: "Pickup Location") { location in
                    pickupLocation = location
                    // Auto-open drop-off picker after pickup is chosen
                    if dropoffLocation == nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            showingDropoffSearch = true
                        }
                    }
                }
            }
            // Drop-off search sheet
            .sheet(isPresented: $showingDropoffSearch) {
                LocationSearchView(prompt: "Drop-off Location") { location in
                    dropoffLocation = location
                }
            }
            // Clear vehicle/driver selection if they are no longer available on the new date
            .onChange(of: startTime) { _, _ in
                if let id = selectedVehicleId,
                   !availableVehicles.contains(where: { $0.id == id }) {
                    selectedVehicleId = nil
                }
                if let id = selectedDriverId,
                   !availableDrivers.contains(where: { $0.id == id }) {
                    selectedDriverId = nil
                }
            }
            // Error alert
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
            // Saving overlay
            .overlay {
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.35).ignoresSafeArea()
                        ProgressView("Saving…")
                            .progressViewStyle(.circular)
                            .foregroundStyle(.white)
                            .padding(32)
                            .background(
                                .ultraThinMaterial,
                                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                            )
                    }
                }
            }
        }
    }

    // MARK: - Save

    private func save() async {
        guard
            let pickup    = pickupLocation,
            let dropoff   = dropoffLocation,
            let vehicleId = selectedVehicleId,
            let driverId  = selectedDriverId
        else { return }

        isSaving = true
        defer { isSaving = false }

        do {
            // 1. Create route record with real addresses
            let route = Route(
                id: UUID(),
                routeName: "\(pickup.title) → \(dropoff.title)",
                startLocation: pickup.fullAddress,
                endLocation: dropoff.fullAddress
            )
            try await RouteService.createRoute(route)

            // 2. Create trip linked to new route
            try await viewModel.addTrip(
                vehicleId: vehicleId,
                driverId: driverId,
                routeId: route.id,
                startTime: startTime,
                orderType: orderType
            )

            dismiss()
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    // MARK: - View Helpers

    @ViewBuilder
    private func locationRowLabel(
        icon: String,
        iconColor: Color,
        caption: String,
        value: String?,
        subtitle: String?,
        isSet: Bool
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: isSet ? 18 : 10))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                Text(value ?? "Search for a location")
                    .font(.body)
                    .foregroundStyle(isSet ? Color.primary : Color(.quaternaryLabel))
                    .lineLimit(1)
                if let sub = subtitle, !sub.isEmpty {
                    Text(sub)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .padding(.vertical, 2)
    }

    private func orderTypeIcon(_ type: OrderType) -> String {
        switch type {
        case .pickUpAndDrop: return "arrow.left.arrow.right"
        case .bulkOrderShip: return "shippingbox.fill"
        case .travel:        return "car.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    AddOrderView(viewModel: OrdersViewModel())
}
