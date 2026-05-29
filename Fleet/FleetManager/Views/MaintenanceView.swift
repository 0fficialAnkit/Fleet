import SwiftUI

struct MaintenanceView: View {
    var viewModel: MaintenanceViewModel

    var body: some View {
        Group {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if viewModel.tasks.isEmpty {
                            Text("No maintenance tasks found.")
                                .foregroundColor(Color.secondary)
                                .padding(.top, 40)
                        } else {
                            ForEach(viewModel.tasks) { task in
                                MaintenanceRowView(task: task, viewModel: viewModel)
                            }
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

struct MaintenanceRowView: View {
    let task: MaintenanceTask
    let viewModel: MaintenanceViewModel
    @State private var isCompleting = false

    var vehicle: Vehicle? { viewModel.getVehicle(for: task.vehicleId) }

    var vehicleName: String {
        guard let v = vehicle else { return "Unknown Vehicle" }
        return "\(v.make ?? "") \(v.model ?? "") (\(v.licensePlate ?? ""))"
    }

    var isAlreadyDone: Bool {
        task.status == .completed || task.status == .cancelled
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(.tertiarySystemBackground))
                        .frame(width: 48, height: 48)
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(vehicleName)
                        .font(.body.bold())
                        .foregroundColor(Color.primary)

                    Text(task.taskType?.rawValue.capitalized.replacingOccurrences(of: "_", with: " ") ?? "Unknown Task")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Color.secondary)

                    if let date = task.scheduledDate {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }

                Spacer()

                Text(task.status?.rawValue.capitalized.replacingOccurrences(of: "_", with: " ") ?? "Unknown")
                    .font(.caption)
                    .foregroundColor(viewModel.getStatusColor(task.status))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(viewModel.getStatusColor(task.status).opacity(0.15))
                    .clipShape(Capsule())
            }

            // Mark Complete button — only shown while task is still pending/in-progress
            if !isAlreadyDone {
                Button {
                    markComplete()
                } label: {
                    HStack(spacing: 8) {
                        if isCompleting {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(isCompleting ? "Completing…" : "Mark Work Complete")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.green.opacity(0.12))
                    .foregroundStyle(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isCompleting)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Complete

    private func markComplete() {
        guard let v = vehicle else { return }
        isCompleting = true

        Task {
            // 1. Mark task completed
            var done = task
            done.status = .completed
            try? await MaintenanceTaskService.updateTask(done)

            // 2. Record in maintenance history
            let history = MaintenanceHistory(
                id: UUID(),
                vehicleId: task.vehicleId,
                workOrderId: task.workOrderId,
                serviceDetails: task.description ?? "Maintenance completed",
                cost: nil,
                completedAt: Date()
            )
            try? await MaintenanceHistoryService.createHistory(history)

            // 3. Return vehicle to active (available) status
            var updated = v
            updated.status = .active
            try? await VehicleService.updateVehicle(updated)

            // 4. Reload so UI reflects the change
            await viewModel.loadData()
            await MainActor.run { isCompleting = false }
        }
    }
}

#Preview {
    NavigationStack {
        MaintenanceView(viewModel: MaintenanceViewModel())
    }
}