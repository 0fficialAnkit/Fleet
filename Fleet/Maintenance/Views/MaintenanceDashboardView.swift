import SwiftUI

struct MaintenanceDashboardView: View {
    @State private var viewModel = MaintenanceDashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary Cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: themeModel.spacingMD) {
                        MetricCard(icon: "clock.badge.exclamationmark", value: "\(viewModel.pendingTasks)", label: "Pending Tasks", color: themeModel.warning)
                        MetricCard(icon: "wrench.adjustable", value: "\(viewModel.inProgressTasks)", label: "In Progress", color: themeModel.info)
                        MetricCard(icon: "checkmark.circle", value: "\(viewModel.completedToday)", label: "Completed Today", color: themeModel.success)
                        MetricCard(icon: "exclamationmark.triangle", value: "\(viewModel.lowStockItemsCount)", label: "Low Stock Items", color: themeModel.danger)
                    }
                    .padding(.horizontal, themeModel.spacingMD)
                    
                    // AI Predictive Maintenance Section
                    VStack(alignment: .leading, spacing: themeModel.spacingMD) {
                        SectionHeader(title: "AI Insights")
                            .padding(.horizontal, themeModel.spacingMD)
                        
                        
                            HStack(alignment: .top, spacing: themeModel.spacingMD) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(themeModel.warning)
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Vehicle MH-12-CX-4490 likely needs brake pad replacement in the next 3 days.")
                                        .font(themeModel.bodyMedium())
                                        .foregroundStyle(themeModel.textPrimary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text("Confidence: 92%")
                                        .font(themeModel.caption())
                                        .foregroundColor(themeModel.textSecondary)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(themeModel.spacingMD)
                            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                            )
                            .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
                        .padding(.horizontal, themeModel.spacingMD)
                    }
                    
                    // Upcoming Scheduled Tasks
                    VStack(alignment: .leading, spacing: themeModel.spacingMD) {
                        SectionHeader(title: "Upcoming Scheduled Maintenance")
                            .padding(.horizontal, themeModel.spacingMD)
                        
                        VStack(spacing: themeModel.spacingMD) {
                            ForEach(viewModel.upcomingTasks) { task in
                                TaskRow(
                                    vehicleId: viewModel.vehicleIdString(for: task.vehicleId),
                                    taskType: viewModel.taskTypeString(for: task.taskType),
                                    date: viewModel.dateString(for: task.scheduledDate)
                                )
                            }
                        }
                        .padding(.horizontal, themeModel.spacingMD)
                    }
                }
                .padding(.vertical, themeModel.spacingMD)
            }
            .background(themeModel.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Dashboard")
        }
    }
}

struct TaskRow: View {
    let vehicleId: String
    let taskType: String
    let date: String
    
    var body: some View {
        
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vehicleId)
                        .font(themeModel.headline())
                        .foregroundStyle(themeModel.textPrimary)
                    Text(taskType)
                        .font(themeModel.bodyMedium())
                        .foregroundColor(themeModel.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(date)
                        .font(themeModel.caption())
                        .foregroundStyle(themeModel.textSecondary)
                    Image(systemName: "chevron.right")
                        .foregroundColor(themeModel.textTertiary)
                        .font(.caption)
                }
            }
            .padding(themeModel.spacingMD)
            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
    }
}

#Preview {
    MaintenanceDashboardView()
}
