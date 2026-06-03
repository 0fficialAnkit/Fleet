import SwiftUI
internal import Auth   // needed for user.id from Supabase Auth module

struct ScheduleMaintenanceSheetView: View {
    let vehicle: Vehicle
    let dashboardViewModel: DashboardViewModel
    @State var viewModel: MaintenanceViewModel
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTaskType: MaintenanceTaskType = .inspection
    @State private var description = ""
    @State private var scheduleType: MaintenanceScheduleType = .date
    @State private var scheduledDate = Date()
    @State private var targetMileage = ""
    @State private var serviceIntervalMonths = 3
    @State private var selectedStaffId: UUID?
    @State private var isSaving = false
    @State private var saveError: String?

    var totalDistance: Double {
        dashboardViewModel.totalDistance(for: vehicle.id)
    }

    var threshold: Double {
        vehicle.vehicleType?.maintenanceThresholdKM ?? 10000
    }

    var isFormValid: Bool {
        !description.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {

                        // Header: Vehicle Details
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(vehicle.make ?? "") \(vehicle.model ?? "")")
                                .font(.title2.bold())
                                .foregroundStyle(Color.primary)

                            HStack {
                                Text(vehicle.licensePlate ?? "NO PLATE")
                                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(Color.teal)

                                Spacer()

                                if totalDistance >= threshold {
                                    StatusBadge(text: "OVERDUE", color: .red)
                                } else {
                                    StatusBadge(text: "APPROACHING", color: .orange)
                                }
                            }
                        }
                        .padding(.top, 8)

                        Divider().background(Color(.separator))

                        // Distance Context
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Odometer")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color(.tertiaryLabel))
                                .textCase(.uppercase)
                            
                            HStack(alignment: .bottom) {
                                Text(String(format: "%.0f", totalDistance))
                                    .font(.title3.bold())
                                    .foregroundStyle(Color.primary)
                                Text("km")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondary)
                                    .padding(.bottom, 2)
                                
                                Spacer()
                                
                                Text("Threshold: \(String(format: "%.0f", threshold)) km")
                                    .font(.caption)
                                    .foregroundStyle(Color.secondary)
                            }
                        }

                        Divider().background(Color(.separator))

                        // Task Configuration
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Task Details")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color(.tertiaryLabel))
                                .textCase(.uppercase)

                            VStack(spacing: 12) {
                                HStack {
                                    Text("Task Type")
                                        .foregroundStyle(Color.primary)
                                    Spacer()
                                    Picker("", selection: $selectedTaskType) {
                                        ForEach(MaintenanceTaskType.allCases, id: \.self) { type in
                                            Text(type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized).tag(type)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                                .padding(12)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                
                                TextField("Description (e.g. Oil Change)", text: $description)
                                    .padding(12)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                DatePicker("Due Date", selection: $scheduledDate, displayedComponents: .date)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }

                        Divider().background(Color(.separator))

                        // Assignment Section (iOS Native Drop Down)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Assign Maintenance Staff")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color(.tertiaryLabel))
                                .textCase(.uppercase)

                            Menu {
                                Button(action: {
                                    withAnimation {
                                        selectedStaffId = nil
                                    }
                                }) {
                                    HStack {
                                        Text("Unassigned")
                                        if selectedStaffId == nil {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }

                                ForEach(viewModel.maintenanceStaff) { staff in
                                    Button(action: {
                                        withAnimation {
                                            selectedStaffId = staff.id
                                        }
                                    }) {
                                        HStack {
                                            Text(staff.fullName)
                                            if selectedStaffId == staff.id {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "wrench.and.screwdriver.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(Color.teal)

                                    if let selectedStaffId = selectedStaffId, let staffName = viewModel.maintenanceStaff.first(where: { $0.id == selectedStaffId })?.fullName {
                                        Text(staffName)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(Color.primary)
                                    } else {
                                        Text("Unassigned")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(Color.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color(.tertiaryLabel))
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.04))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                            }
                        }
                        
                        if let err = saveError {
                            Text(err)
                                .font(.caption)
                                .foregroundStyle(Color.red)
                        }

                    }
                    .padding(24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Schedule Maintenance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        handleSave()
                    }
                    .foregroundStyle(Color.teal)
                    .fontWeight(.semibold)
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
            .task {
                if viewModel.maintenanceStaff.isEmpty {
                    await viewModel.loadData()
                }
            }
        }
    }

    private func handleSave() {
        isSaving = true
        saveError = nil
        Task {
            do {
                let workOrderId = try await WorkOrderService.createWorkOrder(
                    vehicleId: vehicle.id,
                    createdBy: authViewModel.currentUser?.id,
                    assignedTo: selectedStaffId,
                    priority: .medium,
                    status: .open
                )
                
                try await viewModel.addTask(
                    vehicleId: vehicle.id,
                    taskType: selectedTaskType,
                    description: description.trimmingCharacters(in: .whitespaces),
                    scheduledDate: scheduledDate,
                    targetMileage: nil,
                    serviceIntervalMonths: nil,
                    scheduleType: .date,
                    assignedTo: selectedStaffId,
                    scheduledBy: authViewModel.currentUser?.id,
                    workOrderId: workOrderId
                )
                dismiss()
            } catch {
                saveError = error.localizedDescription
                isSaving = false
            }
        }
    }
}
