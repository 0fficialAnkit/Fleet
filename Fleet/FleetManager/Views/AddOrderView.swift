import SwiftUI
import MapKit

struct AddOrderView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: OrdersViewModel

    // MARK: - Form State
    @State private var startTime = Date()
    @State private var orderType: OrderType = .pickUpAndDrop
    @State private var selectedVehicleType: VehicleType = .car
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
        let allAvailable = viewModel.availableVehicles(for: orderType, at: startTime)
        return allAvailable.filter { vehicle in
            if let type = vehicle.vehicleType {
                return type == selectedVehicleType
            }
            return false
        }
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

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { show in
                if !show {
                    viewModel.errorMessage = nil
                }
            }
        )
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                // ── Route ─────────────────────────────────────────────
                Section("Route") {
                    Button(action: { showingPickupSearch = true }) {
                        locationRowLabel(
                            iconColor: .green,
                            caption: "Pickup / Origin",
                            value: pickupLocation?.title,
                            subtitle: pickupLocation?.subtitle,
                            isSet: pickupLocation != nil
                        )
                    }
                    .foregroundStyle(.primary)

                    Button(action: { showingDropoffSearch = true }) {
                        locationRowLabel(
                            iconColor: .red,
                            caption: "Drop-off / Destination",
                            value: dropoffLocation?.title,
                            subtitle: dropoffLocation?.subtitle,
                            isSet: dropoffLocation != nil
                        )
                    }
                    .foregroundStyle(.primary)
                }

                // ── Schedule ──────────────────────────────────────────
                Section("Schedule") {
                    DatePicker(
                        "Date & Time",
                        selection: $startTime,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .tint(Color.teal)
                }

                // ── Order Type ────────────────────────────────────────
                Section("Order Type") {
                    Picker(selection: $orderType) {
                        Text(OrderType.pickUpAndDrop.displayName).tag(OrderType.pickUpAndDrop)
                        Text(OrderType.travel.displayName).tag(OrderType.travel)
                    } label: {
                        Text("Type")
                    }
                    .pickerStyle(.menu)
                    .tint(.primary)
                }

                // ── Vehicle Type ──────────────────────────────────────
                Section("Vehicle Type") {
                    Picker(selection: $selectedVehicleType) {
                        Text(VehicleType.twoWheeler.displayName).tag(VehicleType.twoWheeler)
                        Text(VehicleType.threeWheeler.displayName).tag(VehicleType.threeWheeler)
                        Text(VehicleType.car.displayName).tag(VehicleType.car)
                        Text(VehicleType.truck.displayName).tag(VehicleType.truck)
                    } label: {
                        Text("Vehicle Type")
                    }
                    .pickerStyle(.menu)
                    .tint(.primary)
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
                            Text("Vehicle")
                        }
                    } else {
                        Picker(selection: $selectedVehicleId) {
                            Text("Select a vehicle").tag(nil as UUID?)
                            ForEach(availableVehicles, id: \.id) { (v: Vehicle) in
                                Text("\(v.make ?? "Unknown") \(v.model ?? "") · \(v.licensePlate ?? "—")")
                                    .tag(v.id as UUID?)
                            }
                        } label: {
                            Text("Vehicle")
                        }
                        .pickerStyle(.menu)
                        .tint(.primary)
                    }

                    // Driver picker
                    if availableDrivers.isEmpty {
                        LabeledContent {
                            Text("No drivers available")
                                .foregroundStyle(Color.secondary)
                                .font(.caption)
                        } label: {
                            Text("Driver")
                        }
                    } else {
                        Picker(selection: $selectedDriverId) {
                            Text("Select a driver").tag(nil as UUID?)
                            ForEach(availableDrivers, id: \.id) { (d: Profile) in
                                Text(d.fullName)
                                    .tag(d.id as UUID?)
                            }
                        } label: {
                            Text("Driver")
                        }
                        .pickerStyle(.menu)
                        .tint(.primary)
                    }
                } header: {
                    Text("Assignment")
                } footer: {
                    if !canSave {
                        Text("Fill in all fields to save the order.")
                            .font(.caption)
                    }
                }

                // ── Route Preview ─────────────────────────────────────
                if pickupLocation != nil || dropoffLocation != nil {
                    Section("Route Preview") {
                        TripRouteMapView(
                            startAddress: pickupLocation?.fullAddress,
                            endAddress: dropoffLocation?.fullAddress
                        )
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
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
            // Clear vehicle/driver selection if they are no longer available
            .onChange(of: startTime) { _, _ in validateSelection() }
            .onChange(of: orderType) { _, _ in validateSelection() }
            .onChange(of: selectedVehicleType) { _, _ in validateSelection() }
            // Error alert
            .alert(
                "Error",
                isPresented: isShowingError
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                if let msg = viewModel.errorMessage {
                    Text(msg)
                } else {
                    Text("Unknown error")
                }
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

    // MARK: - Private Helpers

    private func validateSelection() {
        if let id = selectedVehicleId,
           !availableVehicles.contains(where: { $0.id == id }) {
            selectedVehicleId = nil
        }
        if let id = selectedDriverId,
           !availableDrivers.contains(where: { $0.id == id }) {
            selectedDriverId = nil
        }
    }

    private func locationRowLabel(
        iconColor: Color,
        caption: String,
        value: String?,
        subtitle: String?,
        isSet: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(iconColor)
                .frame(width: 8, height: 8)
                .padding(.horizontal, 4)

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
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Preview

#Preview {
    let mockVehicles = [
        Vehicle(
            id: UUID(),
            make: "Honda",
            model: "Activa",
            year: 2024,
            vin: "V123",
            licensePlate: "MH-12-AB-1234",
            tankCapacity: 5,
            mileage: 40,
            purchaseDate: Date(),
            assignedDriverId: nil,
            adminId: nil,
            status: .active,
            vehicleType: .twoWheeler
        ),
        Vehicle(
            id: UUID(),
            make: "TVS",
            model: "King",
            year: 2023,
            vin: "V456",
            licensePlate: "MH-12-CD-5678",
            tankCapacity: 10,
            mileage: 30,
            purchaseDate: Date(),
            assignedDriverId: nil,
            adminId: nil,
            status: .active,
            vehicleType: .threeWheeler
        ),
        Vehicle(
            id: UUID(),
            make: "Tata",
            model: "Nexon",
            year: 2024,
            vin: "V789",
            licensePlate: "MH-12-EF-9012",
            tankCapacity: 44,
            mileage: 18,
            purchaseDate: Date(),
            assignedDriverId: nil,
            adminId: nil,
            status: .active,
            vehicleType: .car
        ),
        Vehicle(
            id: UUID(),
            make: "Ashok Leyland",
            model: "Dost",
            year: 2022,
            vin: "V012",
            licensePlate: "MH-12-GH-3456",
            tankCapacity: 60,
            mileage: 12,
            purchaseDate: Date(),
            assignedDriverId: nil,
            adminId: nil,
            status: .active,
            vehicleType: .truck
        )
    ]
    
    let mockProfiles = [
        Profile(
            id: UUID(),
            fullName: "Ramesh Kumar",
            email: "ramesh@fleet.com",
            phone: "+91 98765 43210",
            licenseNumber: "DL-12345",
            role: "driver",
            status: "active",
            createdAt: Date()
        ),
        Profile(
            id: UUID(),
            fullName: "Suresh Singh",
            email: "suresh@fleet.com",
            phone: "+91 87654 32109",
            licenseNumber: "DL-67890",
            role: "driver",
            status: "active",
            createdAt: Date()
        )
    ]
    
    let mockRoutes = [
        Route(
            id: UUID(),
            routeName: "Office → Warehouse",
            startLocation: "123 Office Road, Mumbai",
            endLocation: "456 Warehouse Lane, Navi Mumbai"
        )
    ]
    
    let viewModel = OrdersViewModel(
        trips: [],
        routes: mockRoutes,
        profiles: mockProfiles,
        vehicles: mockVehicles
    )
    
    return AddOrderView(viewModel: viewModel)
}
