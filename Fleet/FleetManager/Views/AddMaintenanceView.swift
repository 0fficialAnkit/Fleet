import SwiftUI
import Supabase

struct AddMaintenanceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var authViewModel
    var viewModel: MaintenanceViewModel

    @State private var selectedVehicleId: UUID?
    @State private var selectedTaskType: MaintenanceTaskType = .inspection
    @State private var description = ""
    @State private var scheduleType: MaintenanceScheduleType = .date
    @State private var scheduledDate = Date()
    @State private var targetMileage = ""
    @State private var serviceIntervalMonths = 3
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
                Color(.systemGroupedBackground).ignoresSafeArea()

                Form {
                    // Vehicle picker
                    Section(header: Text("Vehicle").foregroundStyle(Color.secondary)) {
                        Picker("Select Vehicle", selection: $selectedVehicleId) {
                            Text("Select a vehicle").tag(UUID?.none)
                            ForEach(viewModel.vehicles) { vehicle in
                                Text("\(vehicle.make ?? "") \(vehicle.model ?? "") (\(vehicle.licensePlate ?? ""))")
                                    .tag(UUID?.some(vehicle.id))
                            }
                        }
                        .foregroundStyle(Color.primary)
                    }
                    .listRowBackground(Color(.systemBackground))

                    // Assign to Maintenance Staff
                    Section(header: Text("Assign To").foregroundStyle(Color.secondary)) {
                        if viewModel.maintenanceStaff.isEmpty {
                            Text("No maintenance staff found. Add staff in Supabase.")
                                .font(.caption)
                                .foregroundStyle(Color(.tertiaryLabel))
                        } else {
                            Picker("Assign to", selection: $selectedAssignedTo) {
                                Text("Unassigned").tag(UUID?.none)
                                ForEach(viewModel.maintenanceStaff) { staff in
                                    Text(staff.fullName).tag(UUID?.some(staff.id))
                                }
                            }
                            .foregroundStyle(Color.primary)
                        }
                    }
                    .listRowBackground(Color(.systemBackground))

                    // Link to Work Order (optional)
                    if !viewModel.workOrders.isEmpty {
                        Section(header: Text("Link Work Order (Optional)").foregroundStyle(Color.secondary)) {
                            Picker("Work Order", selection: $selectedWorkOrderId) {
                                Text("None").tag(UUID?.none)
                                ForEach(viewModel.workOrders) { wo in
                                    Text("WO #\(wo.id.uuidString.prefix(6).uppercased()) — \(wo.priority?.rawValue.capitalized ?? "?")")
                                        .tag(UUID?.some(wo.id))
                                }
                            }
                            .foregroundStyle(Color.primary)
                        }
                        .listRowBackground(Color(.systemBackground))
                    }

                    // Task Details
                    Section(header: Text("Task Details").foregroundStyle(Color.secondary)) {
                        Picker("Task Type", selection: $selectedTaskType) {
                            ForEach(MaintenanceTaskType.allCases, id: \.self) { type in
                                Text(type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .tag(type)
                            }
                        }
                        .foregroundStyle(Color.primary)

                        TextField("", text: $description, prompt: Text("Description").foregroundStyle(Color(.placeholderText)))
                            .foregroundStyle(Color.primary)
                            
                        Picker("Schedule By", selection: $scheduleType) {
                            ForEach(MaintenanceScheduleType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .foregroundStyle(Color.primary)

                        if scheduleType == .date {
                            DatePicker("Scheduled Date", selection: $scheduledDate, displayedComponents: .date)
                                .foregroundStyle(Color.primary)
                                .tint(Color(.label))
                        } else if scheduleType == .mileage {
                            TextField("Target Mileage (km)", text: $targetMileage)
                                .keyboardType(.numberPad)
                                .foregroundStyle(Color.primary)
                        } else if scheduleType == .interval {
                            Picker("Interval (Months)", selection: $serviceIntervalMonths) {
                                Text("1 Month").tag(1)
                                Text("3 Months").tag(3)
                                Text("6 Months").tag(6)
                                Text("12 Months").tag(12)
                            }
                            .foregroundStyle(Color.primary)
                        }
                    }
                    .listRowBackground(Color(.systemBackground))

                    // Error
                    if let err = saveError {
                        Section {
                            Text(err)
                                .font(.caption)
                                .foregroundStyle(Color.red)
                        }
                        .listRowBackground(Color(.systemBackground))
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Add Maintenance Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.primary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let vehicleId = selectedVehicleId else { return }
                        isSaving = true
                        saveError = nil
                        Task {
                            do {
                                let wId: UUID
                                if let selected = selectedWorkOrderId {
                                    wId = selected
                                } else {
                                    wId = try await WorkOrderService.createWorkOrder(
                                        vehicleId: vehicleId,
                                        createdBy: authViewModel.currentUser?.id,
                                        assignedTo: selectedAssignedTo,
                                        priority: .medium,
                                        status: .open
                                    )
                                }
                                
                                try await viewModel.addTask(
                                    vehicleId: vehicleId,
                                    taskType: selectedTaskType,
                                    description: description.trimmingCharacters(in: .whitespaces),
                                    scheduledDate: scheduleType == .date ? scheduledDate : nil,
                                    targetMileage: scheduleType == .mileage ? Double(targetMileage) : nil,
                                    serviceIntervalMonths: scheduleType == .interval ? serviceIntervalMonths : nil,
                                    scheduleType: scheduleType,
                                    assignedTo: selectedAssignedTo,
                                    scheduledBy: authViewModel.currentUser?.id,
                                    workOrderId: wId
                                )
                                dismiss()
                            } catch {
                                saveError = error.localizedDescription
                                print("[AddMaintenanceView] save ERROR: \(error)")
                            }
                            isSaving = false
                        }
                    }
                    .foregroundStyle(Color.primary)
                    .disabled(!isFormValid || isSaving)
                }
            }
            .overlay {
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        ProgressView("Saving…")
                            .tint(.white)
                            .foregroundStyle(.white)
                            .padding(32)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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