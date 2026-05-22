import SwiftUI

struct AddMaintenanceView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: MaintenanceViewModel
    
    @State private var selectedVehicleId: UUID?
    @State private var selectedTaskType: MaintenanceTaskType = .inspection
    @State private var description = ""
    @State private var scheduledDate = Date()
    
    private let vehicles = MockData.vehicles
    
    var isFormValid: Bool {
        selectedVehicleId != nil && !description.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Vehicle").foregroundColor(themeModel.textSecondary)) {
                    Picker("Select Vehicle", selection: $selectedVehicleId) {
                        Text("Select a vehicle").tag(UUID?.none)
                        ForEach(vehicles) { vehicle in
                            Text("\(vehicle.make ?? "") \(vehicle.model ?? "") (\(vehicle.licensePlate ?? ""))")
                                .tag(UUID?.some(vehicle.id))
                        }
                    }
                    .foregroundColor(themeModel.textPrimary)
                }
                .listRowBackground(themeModel.backgroundElevated)
                
                Section(header: Text("Task Details").foregroundColor(themeModel.textSecondary)) {
                    Picker("Task Type", selection: $selectedTaskType) {
                        ForEach(MaintenanceTaskType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized.replacingOccurrences(of: "_", with: " "))
                                .tag(type)
                        }
                    }
                    .foregroundColor(themeModel.textPrimary)
                    
                    TextField("Description", text: $description)
                        .foregroundColor(themeModel.textPrimary)
                    
                    DatePicker("Scheduled Date", selection: $scheduledDate, displayedComponents: .date)
                        .foregroundColor(themeModel.textPrimary)
                        .tint(themeModel.info)
                }
                .listRowBackground(themeModel.backgroundElevated)
            }
            .scrollContentBackground(.hidden)
            .background(themeModel.backgroundPrimary)
            .navigationTitle("Add Maintenance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(themeModel.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeModel.info)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let vehicleId = selectedVehicleId {
                            viewModel.addTask(
                                vehicleId: vehicleId,
                                taskType: selectedTaskType,
                                description: description,
                                scheduledDate: scheduledDate
                            )
                            dismiss()
                        }
                    }
                    .foregroundColor(themeModel.info)
                    .bold()
                    .disabled(!isFormValid)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    AddMaintenanceView(viewModel: MaintenanceViewModel())
}
