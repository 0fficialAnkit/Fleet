import SwiftUI

struct MaintenanceDashboardView: View {
    @State private var viewModel = MaintenanceDashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Cards
                    HStack {
                        SummaryCard(title: "Pending Tasks", count: "\(viewModel.pendingTasks)", icon: "exclamationmark.circle.fill", color: themeModel.warning)
                        SummaryCard(title: "In Progress", count: "\(viewModel.inProgressTasks)", icon: "arrow.triangle.2.circlepath", color: themeModel.info)
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        SummaryCard(title: "Completed Today", count: "\(viewModel.completedToday)", icon: "checkmark.circle.fill", color: themeModel.success)
                        SummaryCard(title: "Low Stock Items", count: "\(viewModel.lowStockItemsCount)", icon: "exclamationmark.triangle.fill", color: themeModel.danger)
                    }
                    .padding(.horizontal)
                    
                    // AI Predictive Maintenance Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("AI Insights")
                            .font(themeModel.headline())
                            .foregroundStyle(themeModel.textPrimary)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading) {
                            HStack(alignment: .top) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(themeModel.warning)
                                    .padding(.top, 2)
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
                        }
                        .background(themeModel.backgroundElevated)
                        .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusMD))
                        .padding(.horizontal)
                    }
                    
                    // Upcoming Scheduled Tasks
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Upcoming Scheduled Maintenance")
                            .font(themeModel.headline())
                            .foregroundStyle(themeModel.textPrimary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ForEach(viewModel.upcomingTasks) { task in
                                TaskRow(
                                    vehicleId: viewModel.vehicleIdString(for: task.vehicleId),
                                    taskType: viewModel.taskTypeString(for: task.taskType),
                                    date: viewModel.dateString(for: task.scheduledDate)
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(themeModel.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Dashboard")
        }
    }
}

struct SummaryCard: View {
    let title: String
    let count: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
                Text(count)
                    .font(themeModel.title())
                    .foregroundStyle(themeModel.textPrimary)
            }
            Text(title)
                .font(themeModel.caption())
                .foregroundColor(themeModel.textSecondary)
        }
        .padding()
        .background(themeModel.backgroundElevated)
        .cornerRadius(themeModel.radiusSM)
        .shadow(color: themeModel.shadowSoft, radius: 5, x: 0, y: 2)
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
        .padding()
        .background(themeModel.backgroundElevated)
        .cornerRadius(themeModel.radiusSM)
    }
}

#Preview {
    MaintenanceDashboardView()
}
