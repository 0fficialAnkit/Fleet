import SwiftUI
import Supabase

struct AddVehicleView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var authViewModel
    var viewModel: VehiclesViewModel

    // Vehicle type
    @State private var selectedType: VehicleType = .car

    // Basic details
    @State private var make = ""
    @State private var model = ""
    @State private var year = ""
    @State private var licensePlate = ""
    @State private var purchaseDate = Date()

    // Specifications (integers only)
    @State private var tankCapacity = ""
    @State private var mileage = ""

    // Compliance & Reminders
    @State private var hasInsuranceExpiry = false
    @State private var insuranceExpiry    = Date()
    @State private var hasServiceExpiry   = false
    @State private var serviceExpiry      = Date()
    @State private var showInsuranceScanner = false
    @State private var showServiceScanner   = false
    @State private var complianceStore = ComplianceSettingsStore.shared

    // State
    @State private var isSaving = false
    @State private var errorMessage: String?

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
                            .tint(Color(.label))

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
                            .tint(Color(.label))

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
            .navigationTitle("Add Vehicle")
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

    // MARK: - Type Card

    private func typeCard(_ type: VehicleType) -> some View {
        let isSelected = selectedType == type
        return Button { selectedType = type } label: {
            VStack(spacing: 8) {
                Image(systemName: typeIcon(type))
                    .font(.title2.weight(.medium))
                    .foregroundStyle(isSelected ? .white : Color.teal)
                Text(type.displayName)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : Color.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? Color.teal : Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.teal : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func typeIcon(_ type: VehicleType) -> String {
        switch type {
        case .twoWheeler:   return "bicycle"
        case .threeWheeler: return "car.rear.fill"
        case .car:          return "car.fill"
        case .truck:        return "truck.box.fill"
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
        let makeTrimmed  = make.trimmingCharacters(in: .whitespaces)
        let modelTrimmed = model.trimmingCharacters(in: .whitespaces)
        let plateTrimmed = licensePlate.trimmingCharacters(in: .whitespaces)

        guard !makeTrimmed.isEmpty, !modelTrimmed.isEmpty, !plateTrimmed.isEmpty else {
            errorMessage = "Make, model, and licence plate are required."
            return
        }

        let yearInt = Int(year) ?? Calendar.current.component(.year, from: Date())
        let cap     = tankCapacity.isEmpty ? nil : Double(tankCapacity)
        let mil     = mileage.isEmpty     ? nil : Double(mileage)

        isSaving = true
        errorMessage = nil

        Task {
            do {
                try await viewModel.addVehicle(
                    make: makeTrimmed,
                    model: modelTrimmed,
                    year: yearInt,
                    tankCapacity: cap,
                    mileage: mil,
                    licensePlate: plateTrimmed,
                    vehicleType: selectedType,
                    adminId: authViewModel.currentUser?.id
                )
                // Best-effort: save purchase date if DB column exists
                if let newVehicle = viewModel.vehicles.first(where: {
                    $0.licensePlate == plateTrimmed
                }) {
                    var updated = newVehicle
                    updated.purchaseDate = purchaseDate
                    try? await VehicleService.updateVehicle(updated)
                }

                // Save compliance dates locally + schedule notifications
                if hasInsuranceExpiry || hasServiceExpiry {
                    let vehicleKey = plateTrimmed.isEmpty ? UUID().uuidString : plateTrimmed
                    var compliance = complianceStore.settings(for: vehicleKey)
                    if hasInsuranceExpiry { compliance.insuranceExpiry = insuranceExpiry }
                    if hasServiceExpiry   { compliance.serviceExpiry   = serviceExpiry   }
                    await MainActor.run { complianceStore.upsert(compliance) }
                }

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

// MARK: - Preview

#Preview {
    AddVehicleView(viewModel: VehiclesViewModel())
        .environment(AuthViewModel())
}
