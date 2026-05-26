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
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                Form {
                    // Vehicle picker
                    Section(header: Text("Vehicle").foregroundColor(Color.secondary)) {
                        Picker("Select Vehicle", selection: $selectedVehicleId) {
                            Text("Select a vehicle").tag(UUID?.none)
                            ForEach(viewModel.vehicles) { vehicle in
                                Text("\(vehicle.make ?? "") \(vehicle.model ?? "") (\(vehicle.licensePlate ?? ""))")
                                    .tag(UUID?.some(vehicle.id))
                            }
                        }
                        .foregroundColor(Color.primary)
                    }
                    .listRowBackground(Color(UIColor.systemBackground))

                    // Assign to Maintenance Staff
                    Section(header: Text("Assign To").foregroundColor(Color.secondary)) {
                        if viewModel.maintenanceStaff.isEmpty {
                            Text("No maintenance staff found. Add staff in Supabase.")
                                .font(.caption)
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                        } else {
                            Picker("Assign to", selection: $selectedAssignedTo) {
                                Text("Unassigned").tag(UUID?.none)
                                ForEach(viewModel.maintenanceStaff) { staff in
                                    Text(staff.fullName).tag(UUID?.some(staff.id))
                                }
                            }
                            .foregroundColor(Color.primary)
                        }
                    }
                    .listRowBackground(Color(UIColor.systemBackground))

                    // Link to Work Order (optional)
                    if !viewModel.workOrders.isEmpty {
                        Section(header: Text("Link Work Order (Optional)").foregroundColor(Color.secondary)) {
                            Picker("Work Order", selection: $selectedWorkOrderId) {
                                Text("None").tag(UUID?.none)
                                ForEach(viewModel.workOrders) { wo in
                                    Text("WO #\(wo.id.uuidString.prefix(6).uppercased()) — \(wo.priority?.rawValue.capitalized ?? "?")")
                                        .tag(UUID?.some(wo.id))
                                }
                            }
                            .foregroundColor(Color.primary)
                        }
                        .listRowBackground(Color(UIColor.systemBackground))
                    }

                    // Task Details
                    Section(header: Text("Task Details").foregroundColor(Color.secondary)) {
                        Picker("Task Type", selection: $selectedTaskType) {
                            ForEach(MaintenanceTaskType.allCases, id: \.self) { type in
                                Text(type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .tag(type)
                            }
                        }
                        .foregroundColor(Color.primary)

                        TextField("", text: $description, prompt: Text("Description").foregroundColor(Color(UIColor.placeholderText)))
                            .foregroundColor(Color.primary)

                        DatePicker("Scheduled Date", selection: $scheduledDate, displayedComponents: .date)
                            .foregroundColor(Color.primary)
                            .tint(Color.blue)
                    }
                    .listRowBackground(Color(UIColor.systemBackground))

                    // Error
                    if let err = saveError {
                        Section {
                            Text(err)
                                .font(.caption)
                                .foregroundColor(Color.red)
                        }
                        .listRowBackground(Color(UIColor.systemBackground))
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color(UIColor.systemGroupedBackground))
            }
            .navigationTitle("Add Maintenance Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.blue)
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
                    .foregroundColor(Color.blue)
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
                            .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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
