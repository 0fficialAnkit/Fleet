import SwiftUI

struct MaintenanceView: View {
    var viewModel: MaintenanceViewModel
    
    var body: some View {
        Group {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: themeModel.spacingMD) {
                        if viewModel.tasks.isEmpty {
                            Text("No maintenance tasks found.")
                                .foregroundColor(themeModel.textSecondary)
                                .padding(.top, 40)
                        } else {
                            ForEach(viewModel.tasks) { task in
                                MaintenanceRowView(task: task, viewModel: viewModel)
                            }
                        }
                    }
                    .padding(.vertical, themeModel.spacingMD)
                    .padding(.horizontal, themeModel.spacingMD)
                }
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
        HStack(spacing: themeModel.spacingMD) {
            ZStack {
                Circle()
                    .fill(themeModel.surfaceTertiary)
                    .frame(width: 48, height: 48)
                
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 20))
                    .foregroundColor(themeModel.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(vehicleName)
                    .font(themeModel.headline(16))
                    .foregroundColor(themeModel.textPrimary)
                
                Text(task.taskType?.rawValue.capitalized.replacingOccurrences(of: "_", with: " ") ?? "Unknown Task")
                    .font(themeModel.bodyMedium(14))
                    .foregroundColor(themeModel.textSecondary)
                
                if let date = task.scheduledDate {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(themeModel.caption(12))
                        .foregroundColor(themeModel.textTertiary)
                }
            }
            
            Spacer()
            
            Text(task.status?.rawValue.capitalized.replacingOccurrences(of: "_", with: " ") ?? "Unknown")
                .font(themeModel.caption(12))
                .foregroundColor(viewModel.getStatusColor(task.status))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(viewModel.getStatusColor(task.status).opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(themeModel.spacingMD)
        .background(themeModel.backgroundElevated)
        .cornerRadius(themeModel.radiusLG)
    }
}

#Preview {
    NavigationStack {
        MaintenanceView(viewModel: MaintenanceViewModel())
    }
}
