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
                .refreshable { await viewModel.loadData() }
            }
        }
    }
}

struct MaintenanceRowView: View {
    let task: MaintenanceTask
    let viewModel: MaintenanceViewModel

    var vehicleName: String {
        guard let v = viewModel.getVehicle(for: task.vehicleId) else { return "Unknown Vehicle" }
        return "\(v.make ?? "") \(v.model ?? "") (\(v.licensePlate ?? ""))"
    }

    var body: some View {
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
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        MaintenanceView(viewModel: MaintenanceViewModel())
    }
}