import SwiftUI

struct MaintenanceView: View {
    var viewModel: MaintenanceViewModel

    var body: some View {
        Group {
            if viewModel.tasks.isEmpty {
                ContentUnavailableView(
                    "No Maintenance Tasks",
                    systemImage: "wrench.and.screwdriver",
                    description: Text("All vehicles are in good shape.")
                )
            } else {
                List {
                    ForEach(viewModel.tasks) { task in
                        MaintenanceRowView(task: task, viewModel: viewModel)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                if task.status != .completed && task.status != .cancelled {
                                    Button {
                                        Task { await completeTask(task) }
                                    } label: {
                                        Label("Complete", systemImage: "checkmark")
                                    }
                                    .tint(.green)
                                }
                            }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    private func completeTask(_ task: MaintenanceTask) async {
        guard let v = viewModel.getVehicle(for: task.vehicleId) else { return }
        var done = task
        done.status = .completed
        try? await MaintenanceTaskService.updateTask(done)
        let history = MaintenanceHistory(
            id: UUID(),
            vehicleId: task.vehicleId,
            workOrderId: task.workOrderId,
            serviceDetails: task.description ?? "Maintenance completed",
            cost: nil,
            completedAt: Date()
        )
        try? await MaintenanceHistoryService.createHistory(history)
        var updated = v
        updated.status = .active
        try? await VehicleService.updateVehicle(updated)
        await viewModel.loadData()
    }
}

struct MaintenanceRowView: View {
    let task: MaintenanceTask
    let viewModel: MaintenanceViewModel
    @State private var isCompleting = false

    var vehicle: Vehicle? { viewModel.getVehicle(for: task.vehicleId) }

    var vehicleName: String {
        guard let v = vehicle else { return "Unknown Vehicle" }
        return "\(v.make ?? "") \(v.model ?? "")"
    }

    var plate: String {
        vehicle?.licensePlate ?? ""
    }

    var taskIcon: String {
        switch task.taskType {
        case .oilChange:      return "drop.fill"
        case .tireRotation:   return "tire"
        case .inspection:     return "magnifyingglass"
        case .repair:         return "wrench.and.screwdriver"
        default:              return "wrench"
        }
    }

    var isAlreadyDone: Bool {
        task.status == .completed || task.status == .cancelled
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isAlreadyDone ? Color(.systemGray5) : Color.orange.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: taskIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isAlreadyDone ? Color.secondary : .orange)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(vehicleName)
                    .font(.headline)
                Text(task.taskType?.rawValue.replacingOccurrences(of: "_", with: " ").capitalized ?? "Task")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !plate.isEmpty {
                    Text(plate)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                if let date = task.scheduledDate {
                    Label(date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            StatusBadge(
                text: task.status?.rawValue.replacingOccurrences(of: "_", with: " ").capitalized ?? "Pending",
                color: viewModel.getStatusColor(task.status)
            )
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        MaintenanceView(viewModel: MaintenanceViewModel())
    }
}
