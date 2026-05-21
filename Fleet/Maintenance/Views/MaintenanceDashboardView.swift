import SwiftUI



// MARK: - Dashboard View
struct MaintenanceDashboardView: View {
    @State private var viewModel = MaintenanceDashboardViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground().ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // ── Stat Cards ──
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            MStatCard(
                                title: "Pending",
                                value: "\(viewModel.pendingTasks)",
                                icon: "clock.badge.exclamationmark",
                                tint: MBlue.pending
                            )
                            MStatCard(
                                title: "In Progress",
                                value: "\(viewModel.inProgressTasks)",
                                icon: "gearshape.2",
                                tint: MBlue.inProgress
                            )
                            MStatCard(
                                title: "Completed Today",
                                value: "\(viewModel.completedToday)",
                                icon: "checkmark.seal",
                                tint: MBlue.completed
                            )
                            MStatCard(
                                title: "Low Stock",
                                value: "\(viewModel.lowStockItemsCount)",
                                icon: "exclamationmark.triangle",
                                tint: MBlue.critical
                            )
                        }
                        .padding(.horizontal)

                        // ── AI Insights ──
                        AIInsightCard()

                        // ── Upcoming Tasks ──
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Upcoming Maintenance", icon: "calendar.badge.clock")

                            VStack(spacing: 10) {
                                ForEach(viewModel.upcomingTasks) { task in
                                    MTaskRow(
                                        vehicleId: viewModel.vehicleIdString(for: task.vehicleId),
                                        taskType: viewModel.taskTypeString(for: task.taskType),
                                        date: viewModel.dateString(for: task.scheduledDate),
                                        status: task.status
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Stat Card
struct MStatCard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(tint.opacity(0.12))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(tint)
                        .symbolRenderingMode(.hierarchical)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(MBlue.textPrimary)
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(tint.opacity(0.75))
            }
        }
        .padding(12)
        .mCard()
    }
}

// MARK: - AI Insight Card
struct AIInsightCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(MBlue.accentLight.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MBlue.accentBright)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("AI Insight")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(MBlue.accentLight)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    Spacer()
                    Text("92% confidence")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(MBlue.accentBright)
                }

                Text("Vehicle MH-12-CX-4490 likely needs brake pad replacement in the next 3 days.")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(MBlue.textPrimary)
                    .lineSpacing(2)
            }
        }
        .padding(14)
        .glassEffect(
            .regular,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(MBlue.accentBorder.opacity(0.6), lineWidth: 0.8)
        )
        .padding(.horizontal)
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(MBlue.accent)
                .symbolRenderingMode(.hierarchical)
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(MBlue.textPrimary)
            Spacer()
        }
    }
}

// MARK: - Task Row
struct MTaskRow: View {
    let vehicleId: String
    let taskType: String
    let date: String
    let status: MaintenanceTaskStatus?

    private var statusColor: Color {
        switch status {
        case .pending:    return MBlue.pending
        case .inProgress: return MBlue.inProgress
        case .completed:  return MBlue.completed
        default:          return MBlue.textMuted
        }
    }

    private var statusLabel: String {
        switch status {
        case .pending:    return "Pending"
        case .inProgress: return "In Progress"
        case .completed:  return "Completed"
        case .cancelled:  return "Cancelled"
        default:          return "Unknown"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Status indicator strip
            RoundedRectangle(cornerRadius: 2)
                .fill(statusColor)
                .frame(width: 3, height: 38)

            VStack(alignment: .leading, spacing: 3) {
                Text(vehicleId)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MBlue.accentLight)
                Text(taskType)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(MBlue.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(date)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(MBlue.textMuted)
                Text(statusLabel)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(statusColor)
                    .textCase(.uppercase)
                    .tracking(0.4)
            }
        }
        .padding(11)
        .mCardSM()
    }
}

#Preview {
    MaintenanceDashboardView()
}
