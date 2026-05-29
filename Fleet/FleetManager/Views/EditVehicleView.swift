import SwiftUI
import UserNotifications

struct EditVehicleView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: VehiclesViewModel
    var vehicle: Vehicle

    @State private var make: String
    @State private var model: String
    @State private var year: String
    @State private var licensePlate: String
    @State private var tankCapacity: String
    @State private var mileage: String
    @State private var purchaseDate: Date
    @State private var isSaving = false
    @State private var selectedType: VehicleType

    // Compliance settings — loaded from store, edited here, saved on confirm
    @State private var complianceSettings: ComplianceSettings

    private var vehicleKey: String {
        vehicle.licensePlate ?? vehicle.id.uuidString
    }

    init(viewModel: VehiclesViewModel, vehicle: Vehicle) {
        self.viewModel = viewModel
        self.vehicle   = vehicle

        _make          = State(initialValue: vehicle.make ?? "")
        _model         = State(initialValue: vehicle.model ?? "")
        _year          = State(initialValue: vehicle.year != nil ? String(vehicle.year!) : "")
        _licensePlate  = State(initialValue: vehicle.licensePlate ?? "")
        _tankCapacity  = State(initialValue: vehicle.tankCapacity != nil ? String(vehicle.tankCapacity!) : "")
        _mileage       = State(initialValue: vehicle.mileage != nil ? String(vehicle.mileage!) : "")
        _purchaseDate  = State(initialValue: vehicle.purchaseDate ?? Date())
        _selectedType  = State(initialValue: vehicle.vehicleType ?? .car)

        // Load existing compliance settings for this vehicle
        let key = vehicle.licensePlate ?? vehicle.id.uuidString
        _complianceSettings = State(
            initialValue: ComplianceSettingsStore.shared.settings(for: key)
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // ── Basic Details ────────────────────────────────────────────
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Basic Details")
                                .padding(.horizontal, 16)

                            VStack(spacing: 0) {
                                TextField("", text: $make,
                                          prompt: Text("Manufacturer (e.g. Ford)")
                                              .foregroundColor(Color(.placeholderText)))
                                    .padding(.vertical, 12)
                                    .foregroundColor(Color.primary)

                                Divider().background(Color(.separator))

                                TextField("", text: $model,
                                          prompt: Text("Model (e.g. Transit)")
                                              .foregroundColor(Color(.placeholderText)))
                                    .padding(.vertical, 12)
                                    .foregroundColor(Color.primary)

                                Divider().background(Color(.separator))

                                TextField("", text: $year,
                                          prompt: Text("Year (e.g. 2024)")
                                              .foregroundColor(Color(.placeholderText)))
                                    .keyboardType(.numberPad)
                                    .padding(.vertical, 12)
                                    .foregroundColor(Color.primary)

                                Divider().background(Color(.separator))

                                TextField("", text: $licensePlate,
                                          prompt: Text("License Plate")
                                              .foregroundColor(Color(.placeholderText)))
                                    .textInputAutocapitalization(.characters)
                                    .padding(.vertical, 12)
                                    .foregroundColor(Color.primary)

                                Divider().background(Color(.separator))

                                HStack {
                                    Text("Vehicle Type")
                                        .foregroundColor(Color.primary)
                                    Spacer()
                                    Picker("", selection: $selectedType) {
                                        ForEach(VehicleType.allCases) { type in
                                            Text(type.displayName).tag(type)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                                .padding(.vertical, 8)
                            }
                            .padding(16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .padding(.horizontal, 16)
                        }

                        // ── Specifications ───────────────────────────────────────────
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Specifications")
                                .padding(.horizontal, 16)

                            VStack(spacing: 0) {
                                TextField("", text: $tankCapacity,
                                          prompt: Text("Tank Capacity (L)")
                                              .foregroundColor(Color(.placeholderText)))
                                    .keyboardType(.decimalPad)
                                    .padding(.vertical, 12)
                                    .foregroundColor(Color.primary)

                                Divider().background(Color(.separator))

                                TextField("", text: $mileage,
                                          prompt: Text("Mileage (km/l)")
                                              .foregroundColor(Color(.placeholderText)))
                                    .keyboardType(.decimalPad)
                                    .padding(.vertical, 12)
                                    .foregroundColor(Color.primary)

                                Divider().background(Color(.separator))

                                DatePicker("Purchase Date", selection: $purchaseDate,
                                           displayedComponents: .date)
                                    .padding(.vertical, 12)
                                    .foregroundColor(Color.primary)
                                    .tint(Color.teal)
                            }
                            .padding(16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .padding(.horizontal, 16)
                        }

                        // ── Live Compliance Preview ──────────────────────────────────
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Current Compliance")
                                .padding(.horizontal, 16)
                            VehicleComplianceStatusCard(vehicleId: vehicleKey)
                        }

                        // ── Compliance Reminder Settings ─────────────────────────────
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Compliance & Reminders")
                                .padding(.horizontal, 16)
                            ComplianceReminderCard(settings: $complianceSettings)
                                .padding(.horizontal, 16)
                        }

                        Color.clear.frame(height: 16)
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Edit Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.teal)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .foregroundColor(Color.teal)
                    .bold()
                    .disabled(isSaving)
                }
            }
            .overlay {
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.35).ignoresSafeArea()
                        VStack(spacing: 14) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                            Text("Saving…")
                                .font(.body.weight(.medium))
                                .foregroundColor(.white)
                        }
                        .padding(28)
                        .background(.ultraThinMaterial,
                                    in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }
            }
            .task {
                _ = try? await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound, .badge])
            }
        }
    }

    // MARK: - Save

    private func save() async {
        isSaving = true

        let yearInt   = Int(year.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 2024
        let cap       = Double(tankCapacity.trimmingCharacters(in: .whitespacesAndNewlines))
        let mil       = Double(mileage.trimmingCharacters(in: .whitespacesAndNewlines))

        var updated              = vehicle
        updated.make             = make.isEmpty ? "Unknown" : make
        updated.model            = model.isEmpty ? "Unknown" : model
        updated.year             = yearInt
        updated.licensePlate     = licensePlate.isEmpty ? "NO-PLATE" : licensePlate
        updated.tankCapacity     = cap
        updated.mileage          = mil
        updated.purchaseDate     = purchaseDate
        updated.vehicleType      = selectedType

        do {
            try await viewModel.updateVehicle(updated)

            // Update compliance settings — re-key if the license plate changed
            var finalSettings        = complianceSettings
            finalSettings.vehicleId  = updated.licensePlate ?? vehicle.id.uuidString
            ComplianceSettingsStore.shared.upsert(finalSettings)

            dismiss()
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

#Preview {
    EditVehicleView(
        viewModel: VehiclesViewModel(),
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
        )
    )
}
