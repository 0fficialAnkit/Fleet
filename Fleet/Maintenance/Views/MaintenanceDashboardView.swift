import SwiftUI
import Supabase

struct MaintenanceDashboardView: View {
    @State private var viewModel = MaintenanceDashboardViewModel()
    @State private var isShowingProfile = false
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: themeModel.spacingLG) {

                        // MARK: - KPI Summary Cards
                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: themeModel.spacingMD
                        ) {
                            MetricCard(
                                icon: "clock.badge.exclamationmark",
                                value: "\(viewModel.pendingTasks)",
                                label: "Pending Tasks",
                                color: themeModel.warning
                            )
                            MetricCard(
                                icon: "wrench.adjustable",
                                value: "\(viewModel.inProgressTasks)",
                                label: "In Progress",
                                color: themeModel.info
                            )
                            MetricCard(
                                icon: "checkmark.seal.fill",
                                value: "\(viewModel.completedToday)",
                                label: "Completed Today",
                                color: themeModel.success
                            )
                            MetricCard(
                                icon: "exclamationmark.triangle.fill",
                                value: "\(viewModel.lowStockItemsCount)",
                                label: "Low Stock Items",
                                color: themeModel.danger
                            )
                        }
                        .padding(.horizontal, themeModel.spacingMD)

                        // MARK: - Upcoming Scheduled Tasks
                        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
                            SectionHeader(title: "Upcoming Maintenance")
                                .padding(.horizontal, themeModel.spacingMD)

                            if viewModel.upcomingTasks.isEmpty {
                                HStack {
                                    Spacer()
                                    VStack(spacing: themeModel.spacingSM) {
                                        Image(systemName: "calendar.badge.checkmark")
                                            .font(.system(size: 32))
                                            .foregroundStyle(themeModel.textTertiary)
                                        Text("No upcoming tasks")
                                            .font(themeModel.bodyMedium())
                                            .foregroundStyle(themeModel.textSecondary)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, themeModel.spacingLG)
                            } else {
                                VStack(spacing: themeModel.spacingMD) {
                                    ForEach(viewModel.upcomingTasks) { task in
                                        TaskRow(
                                            vehicleId: viewModel.vehicleIdString(for: task.vehicleId),
                                            taskType: viewModel.taskTypeString(for: task.taskType),
                                            date: viewModel.dateString(for: task.scheduledDate),
                                            status: task.status
                                        )
                                    }
                                }
                                .padding(.horizontal, themeModel.spacingMD)
                            }
                        }

                    }
                    .padding(.vertical, themeModel.spacingMD)
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { isShowingProfile = true }) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 28, weight: .medium))
//                            .foregroundStyle(themeModel.maintenancePrimary)
                    }
                }
            }
            .sheet(isPresented: $isShowingProfile) {
                MaintenanceProfileView()
                    .environment(authViewModel)
            }
            .task {
                viewModel.currentUserId = authViewModel.currentUser?.id
                await viewModel.loadData()
                viewModel.setupRealtime()
            }
        }
    }
}

// MARK: - Task Row
struct TaskRow: View {
    let vehicleId: String
    let taskType: String
    let date: String
    var status: MaintenanceTaskStatus?

    var statusColor: Color {
        switch status {
        case .pending:    return themeModel.warning
        case .inProgress: return themeModel.info
        case .completed:  return themeModel.success
        case .cancelled:  return themeModel.danger
        case .none:       return themeModel.textTertiary
        }
    }

    var body: some View {
        HStack(spacing: themeModel.spacingMD) {
            // Status dot
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                Text(vehicleId)
                    .font(themeModel.headline())
                    .foregroundStyle(themeModel.textPrimary)
                Text(taskType)
                    .font(themeModel.bodyMedium())
                    .foregroundStyle(themeModel.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(date)
                    .font(themeModel.caption())
                    .foregroundStyle(themeModel.textTertiary)
                Image(systemName: "chevron.right")
                    .foregroundStyle(themeModel.textDisabled)
                    .font(.caption2)
            }
        }
        .padding(themeModel.spacingMD)
        .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
        )
        .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
    }
}

#Preview {
    MaintenanceDashboardView()
        .environment(AuthViewModel())
}
