import SwiftUI
import UserNotifications

struct AddVehicleView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: VehiclesViewModel

    /// Called with the newly created Vehicle after a successful save.
    var onSaved: ((Vehicle) -> Void)? = nil

    @State private var make          = ""
    @State private var model         = ""
    @State private var year          = ""
    @State private var licensePlate  = ""
    @State private var tankCapacity  = ""
    @State private var mileage       = ""
    @State private var isSaving      = false
    @State private var errorMessage: String?

    // Temporary vehicleId so compliance settings can be linked on save
    @State private var tempVehicleId = UUID()

    // Compliance settings bound to the card
    @State private var complianceSettings: ComplianceSettings

    init(viewModel: VehiclesViewModel, onSaved: ((Vehicle) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onSaved   = onSaved
        let tempId = UUID()
        _tempVehicleId       = State(initialValue: tempId)
        _complianceSettings  = State(initialValue: ComplianceSettings(vehicleId: tempId.uuidString))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // Error banner
                        if let error = errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.red)
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 16)
                        }

                        // ── Basic Details ───────────────────────────────────────
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Basic Details")
                                .padding(.horizontal, 16)

                            VStack(spacing: 0) {
                                field(text: $make,         prompt: "Manufacturer (e.g. Ford)")
                                Divider().background(Color(.separator))
                                field(text: $model,        prompt: "Model (e.g. Transit)")
                                Divider().background(Color(.separator))
                                field(text: $year,         prompt: "Year (e.g. 2024)",  keyboard: .numberPad)
                                Divider().background(Color(.separator))
                                field(text: $licensePlate, prompt: "License Plate",      autocap: .characters)
                            }
                            .padding(16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .padding(.horizontal, 16)
                        }

                        // ── Specifications ──────────────────────────────────────
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Specifications")
                                .padding(.horizontal, 16)

                            VStack(spacing: 0) {
                                field(text: $tankCapacity, prompt: "Tank Capacity (L)",  keyboard: .decimalPad)
                                Divider().background(Color(.separator))
                                field(text: $mileage,      prompt: "Mileage (km/l)",      keyboard: .decimalPad)
                            }
                            .padding(16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .padding(.horizontal, 16)
                        }

                        // ── Compliance & Reminders ──────────────────────────────
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
            .navigationTitle("Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.teal)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .foregroundColor(Color.teal)
                        .bold()
                        .disabled(isSaving)
                }
            }
            .overlay {
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                            Text("Adding vehicle...")
                                .font(.body.weight(.medium))
                                .foregroundColor(.white)
                        }
                        .padding(32)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }
            }
            .task {
                _ = try? await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound, .badge])
            }
        }
    }

    // MARK: - Helper

    @ViewBuilder
    private func field(
        text: Binding<String>,
        prompt: String,
        keyboard: UIKeyboardType = .default,
        autocap: TextInputAutocapitalization = .sentences
    ) -> some View {
        TextField("", text: text,
                  prompt: Text(prompt).foregroundColor(Color(.placeholderText)))
            .keyboardType(keyboard)
            .textInputAutocapitalization(autocap)
            .padding(.vertical, 12)
            .foregroundColor(Color.primary)
    }

    // MARK: - Save

    private func save() async {
        isSaving     = true
        errorMessage = nil

        let yearInt   = Int(year.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 2024
        let cap       = Double(tankCapacity.trimmingCharacters(in: .whitespacesAndNewlines))
        let mil       = Double(mileage.trimmingCharacters(in: .whitespacesAndNewlines))
        let makeTrim  = make.trimmingCharacters(in: .whitespacesAndNewlines)
        let modelTrim = model.trimmingCharacters(in: .whitespacesAndNewlines)
        let plateTrim = licensePlate.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !makeTrim.isEmpty, !modelTrim.isEmpty, !plateTrim.isEmpty else {
            errorMessage = "Make, model, and license plate are required."
            isSaving = false
            return
        }

        do {
            let newVehicle = try await viewModel.addVehicle(
                make:         makeTrim,
                model:        modelTrim,
                year:         yearInt,
                tankCapacity: cap,
                mileage:      mil,
                licensePlate: plateTrim
            )

            // Persist compliance settings keyed by license plate
            var finalSettings = complianceSettings
            finalSettings.vehicleId = plateTrim
            ComplianceSettingsStore.shared.upsert(finalSettings)

            // Dismiss first, then navigate to the new vehicle's detail
            dismiss()
            onSaved?(newVehicle)

        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

#Preview {
    AddVehicleView(viewModel: VehiclesViewModel())
}
