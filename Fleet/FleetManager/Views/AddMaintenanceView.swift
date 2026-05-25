import SwiftUI
import Supabase

struct AddMaintenanceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var authViewModel
    var viewModel: MaintenanceViewModel

    @State private var selectedVehicleId: UUID?
    @State private var selectedTaskType: MaintenanceTaskType = .inspection
    @State private var description = ""
    @State private var scheduledDate = Date()
    @State private var selectedAssignedTo: UUID?
    @State private var selectedWorkOrderId: UUID?
    @State private var isSaving = false
    @State private var saveError: String?

    var isFormValid: Bool {
        selectedVehicleId != nil && !description.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()

                Form {
                    // Vehicle picker
                    Section(header: Text("Vehicle").foregroundColor(themeModel.textSecondary)) {
                        Picker("Select Vehicle", selection: $selectedVehicleId) {
                            Text("Select a vehicle").tag(UUID?.none)
                            ForEach(viewModel.vehicles) { vehicle in
                                Text("\(vehicle.make ?? "") \(vehicle.model ?? "") (\(vehicle.licensePlate ?? ""))")
                                    .tag(UUID?.some(vehicle.id))
                            }
                        }
                        .foregroundColor(themeModel.textPrimary)
                    }
                    .listRowBackground(themeModel.backgroundElevated)

                    // Assign to Maintenance Staff
                    Section(header: Text("Assign To").foregroundColor(themeModel.textSecondary)) {
                        if viewModel.maintenanceStaff.isEmpty {
                            Text("No maintenance staff found. Add staff in Supabase.")
                                .font(.caption)
                                .foregroundColor(themeModel.textTertiary)
                        } else {
                            Picker("Assign to", selection: $selectedAssignedTo) {
                                Text("Unassigned").tag(UUID?.none)
                                ForEach(viewModel.maintenanceStaff) { staff in
                                    Text(staff.fullName).tag(UUID?.some(staff.id))
                                }
                            }
                            .foregroundColor(themeModel.textPrimary)
                        }
                    }
                    .listRowBackground(themeModel.backgroundElevated)

                    // Link to Work Order (optional)
                    if !viewModel.workOrders.isEmpty {
                        Section(header: Text("Link Work Order (Optional)").foregroundColor(themeModel.textSecondary)) {
                            Picker("Work Order", selection: $selectedWorkOrderId) {
                                Text("None").tag(UUID?.none)
                                ForEach(viewModel.workOrders) { wo in
                                    Text("WO #\(wo.id.uuidString.prefix(6).uppercased()) — \(wo.priority?.rawValue.capitalized ?? "?")")
                                        .tag(UUID?.some(wo.id))
                                }
                            }
                            .foregroundColor(themeModel.textPrimary)
                        }
                        .listRowBackground(themeModel.backgroundElevated)
                    }

                    // Task Details
                    Section(header: Text("Task Details").foregroundColor(themeModel.textSecondary)) {
                        Picker("Task Type", selection: $selectedTaskType) {
                            ForEach(MaintenanceTaskType.allCases, id: \.self) { type in
                                Text(type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .tag(type)
                            }
                        }
                        .foregroundColor(themeModel.textPrimary)

                        TextField("", text: $description, prompt: Text("Description").foregroundColor(themeModel.placeholder))
                            .foregroundColor(themeModel.textPrimary)

                        DatePicker("Scheduled Date", selection: $scheduledDate, displayedComponents: .date)
                            .foregroundColor(themeModel.textPrimary)
                            .tint(themeModel.accent)
                    }
                    .listRowBackground(themeModel.backgroundElevated)

                    // Error
                    if let err = saveError {
                        Section {
                            Text(err)
                                .font(.caption)
                                .foregroundColor(themeModel.danger)
                        }
                        .listRowBackground(themeModel.backgroundElevated)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(themeModel.backgroundPrimary)
            }
            .navigationTitle("Add Maintenance Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(themeModel.accent)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let vehicleId = selectedVehicleId else { return }
                        isSaving = true
                        saveError = nil
                        Task {
                            do {
                                try await viewModel.addTask(
                                    vehicleId: vehicleId,
                                    taskType: selectedTaskType,
                                    description: description.trimmingCharacters(in: .whitespaces),
                                    scheduledDate: scheduledDate,
                                    assignedTo: selectedAssignedTo,
                                    scheduledBy: authViewModel.currentUser?.id,
                                    workOrderId: selectedWorkOrderId
                                )
                                dismiss()
                            } catch {
                                saveError = error.localizedDescription
                                print("[AddMaintenanceView] save ERROR: \(error)")
                            }
                            isSaving = false
                        }
                    }
                    .foregroundColor(themeModel.accent)
                    .bold()
                    .disabled(!isFormValid || isSaving)
                }
            }
            .overlay {
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        ProgressView("Saving…")
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .foregroundColor(.white)
                            .padding(32)
                            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                    }
                }
            }
        }
    }
}

#Preview {
    AddMaintenanceView(viewModel: MaintenanceViewModel())
        .environment(AuthViewModel())
}
