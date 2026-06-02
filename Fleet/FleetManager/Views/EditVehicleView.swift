import SwiftUI
import Supabase

struct EditVehicleView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: VehiclesViewModel
    var vehicle: Vehicle

    // Vehicle type
    @State private var selectedType: VehicleType

    // Basic details
    @State private var make: String
    @State private var model: String
    @State private var year: String
    @State private var licensePlate: String
    @State private var purchaseDate: Date

    // Specifications (integers only)
    @State private var tankCapacity: String
    @State private var mileage: String

    // Compliance & Reminders
    @State private var hasInsuranceExpiry: Bool
    @State private var insuranceExpiry: Date
    @State private var hasServiceExpiry: Bool
    @State private var serviceExpiry: Date
    @State private var showInsuranceScanner = false
    @State private var showServiceScanner   = false
    @State private var complianceStore = ComplianceSettingsStore.shared

    // State
    @State private var isSaving = false
    @State private var errorMessage: String?

    @MainActor
    init(viewModel: VehiclesViewModel, vehicle: Vehicle) {
        self.viewModel = viewModel
        self.vehicle = vehicle

        _make = State(initialValue: vehicle.make ?? "")
        _model = State(initialValue: vehicle.model ?? "")
        _year = State(initialValue: vehicle.year != nil ? String(vehicle.year!) : "")
        _licensePlate = State(initialValue: vehicle.licensePlate ?? "")
        _purchaseDate = State(initialValue: vehicle.purchaseDate ?? Date())
        _selectedType = State(initialValue: vehicle.vehicleType ?? .car)

        // Convert specs to whole numbers/integers if present to match AddVehicleView
        _tankCapacity = State(initialValue: vehicle.tankCapacity != nil ? String(Int(vehicle.tankCapacity!)) : "")
        _mileage = State(initialValue: vehicle.mileage != nil ? String(Int(vehicle.mileage!)) : "")

        let key = vehicle.licensePlate ?? vehicle.id.uuidString
        let compliance = ComplianceSettingsStore.shared.settings(for: key)
        
        if let ins = compliance.insuranceExpiry {
            _hasInsuranceExpiry = State(initialValue: true)
            _insuranceExpiry = State(initialValue: ins)
        } else {
            _hasInsuranceExpiry = State(initialValue: false)
            _insuranceExpiry = State(initialValue: Date())
        }
        
        if let svc = compliance.serviceExpiry {
            _hasServiceExpiry = State(initialValue: true)
            _serviceExpiry = State(initialValue: svc)
        } else {
            _hasServiceExpiry = State(initialValue: false)
            _serviceExpiry = State(initialValue: Date())
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {

                // ── Vehicle Type ─────────────────────────────────────
                Section("Vehicle Type") {
                    Picker("Vehicle Type", selection: $selectedType) {
                        ForEach(VehicleType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.primary)
                }

                // ── Basic Details ─────────────────────────────────────
                Section("Basic Details") {
                    TextField("Manufacturer (e.g. Tata)", text: $make)
                        .textInputAutocapitalization(.words)

                    TextField("Model (e.g. Ace)", text: $model)
                        .textInputAutocapitalization(.words)

                    TextField("Year (e.g. 2024)", text: $year)
                        .keyboardType(.numberPad)
                        .onChange(of: year) { _, new in
                            year = String(new.filter(\.isNumber).prefix(4))
                        }

                    TextField("License Plate", text: $licensePlate)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()

                    DatePicker(
                        "Purchase Date",
                        selection: $purchaseDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                }

                // ── Specifications ─────────────────────────────────────
                Section {
                    HStack {
                        Text("Tank Capacity")
                        Spacer()
                        TextField("0", text: $tankCapacity)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                            .onChange(of: tankCapacity) { _, new in
                                tankCapacity = String(new.filter(\.isNumber).prefix(4))
                            }
                        Text("L")
                            .foregroundStyle(Color.secondary)
                            .frame(width: 20)
                    }

                    HStack {
                        Text("Mileage")
                        Spacer()
                        TextField("0", text: $mileage)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                            .onChange(of: mileage) { _, new in
                                mileage = String(new.filter(\.isNumber).prefix(4))
                            }
                        Text("km/L")
                            .foregroundStyle(Color.secondary)
                            .frame(width: 44)
                    }
                } header: {
                    Text("Specifications")
                } footer: {
                    Text("Enter whole numbers only.")
                }

                // ── Compliance & Reminders ────────────────────────────
                Section {
                    // Insurance
                    Toggle("Insurance Expiry", isOn: $hasInsuranceExpiry)

                    if hasInsuranceExpiry {
                        DatePicker("Expiry Date", selection: $insuranceExpiry,
                                   in: Date()..., displayedComponents: .date)
                            .tint(Color.teal)

                        Button {
                            showInsuranceScanner = true
                        } label: {
                            Label("Scan Insurance Document", systemImage: "doc.text.viewfinder")
                                .foregroundStyle(Color.teal)
                        }
                    }
                } header: {
                    Text("Insurance")
                } footer: {
                    if hasInsuranceExpiry {
                        Text("You will receive alerts 30, 15, 7 and 1 day before expiry.")
                    }
                }

                Section {
                    // Service
                    Toggle("Next Service Due", isOn: $hasServiceExpiry)

                    if hasServiceExpiry {
                        DatePicker("Service Date", selection: $serviceExpiry,
                                   in: Date()..., displayedComponents: .date)
                            .tint(Color.teal)

                        Button {
                            showServiceScanner = true
                        } label: {
                            Label("Scan Service Receipt", systemImage: "doc.text.viewfinder")
                                .foregroundStyle(Color.teal)
                        }
                    }
                } header: {
                    Text("Service")
                } footer: {
                    if hasServiceExpiry {
                        Text("You will receive a reminder before the service date.")
                    }
                }

                // ── Error ─────────────────────────────────────────────
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(Color.red)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Edit Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") { save() }
                            .foregroundStyle(Color.primary)
                            .disabled(!isValid)
                    }
                }
            }
            .sheet(isPresented: $showInsuranceScanner) {
                OCRDateScannerSheet(target: .insurance) { date in
                    insuranceExpiry    = date
                    hasInsuranceExpiry = true
                }
            }
            .sheet(isPresented: $showServiceScanner) {
                OCRDateScannerSheet(target: .insurance) { date in
                    serviceExpiry    = date
                    hasServiceExpiry = true
                }
            }
        }
    }

    // MARK: - Validation

    private var isValid: Bool {
        !make.trimmingCharacters(in: .whitespaces).isEmpty &&
        !model.trimmingCharacters(in: .whitespaces).isEmpty &&
        !licensePlate.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Save

    private func save() {
        let makeTrimmed  = make.trimmingCharacters(in: .whitespacesAndNewlines)
        let modelTrimmed = model.trimmingCharacters(in: .whitespacesAndNewlines)
        let plateTrimmed = licensePlate.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !makeTrimmed.isEmpty, !modelTrimmed.isEmpty, !plateTrimmed.isEmpty else {
            errorMessage = "Make, model, and licence plate are required."
            return
        }

        let yearInt = Int(year) ?? Calendar.current.component(.year, from: Date())
        let cap     = tankCapacity.isEmpty ? nil : Double(tankCapacity)
        let mil     = mileage.isEmpty     ? nil : Double(mileage)

        isSaving = true
        errorMessage = nil

        var updatedVehicle = vehicle
        updatedVehicle.make = makeTrimmed
        updatedVehicle.model = modelTrimmed
        updatedVehicle.year = yearInt
        updatedVehicle.licensePlate = plateTrimmed
        updatedVehicle.tankCapacity = cap
        updatedVehicle.mileage = mil
        updatedVehicle.purchaseDate = purchaseDate
        updatedVehicle.vehicleType = selectedType

        Task {
            do {
                try await viewModel.updateVehicle(updatedVehicle)
                
                // Save compliance dates locally + schedule notifications
                let vehicleKey = plateTrimmed.isEmpty ? vehicle.id.uuidString : plateTrimmed
                var compliance = complianceStore.settings(for: vehicleKey)
                compliance.insuranceExpiry = hasInsuranceExpiry ? insuranceExpiry : nil
                compliance.serviceExpiry   = hasServiceExpiry   ? serviceExpiry   : nil
                await MainActor.run { complianceStore.upsert(compliance) }

                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSaving = false
                }
            }
        }
    }
}
