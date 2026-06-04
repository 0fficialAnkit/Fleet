import SwiftUI
import Charts

// MARK: - Daily Repair Data Point
struct DailyRepairData: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int

    var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        return formatter.string(from: date)
    }
}

// MARK: - Performance Report View
struct PerformanceReportView: View {
    @State private var repairData: [DailyRepairData] = []
    @State private var isLoading = false
    @State private var selectedBar: DailyRepairData? = nil
    @State private var timeRange: TimeRange = .week

    enum TimeRange: String, CaseIterable {
        case week = "7 Days"
        case twoWeeks = "14 Days"
        case month = "30 Days"
    }

    var totalRepairs: Int { repairData.reduce(0) { $0 + $1.count } }
    var averageDaily: Double {
        repairData.isEmpty ? 0 : Double(totalRepairs) / Double(repairData.count)
    }
    var bestDay: DailyRepairData? {
        repairData.max(by: { $0.count < $1.count })
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            if isLoading {
                VStack(spacing: 14) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .brown))
                        .scaleEffect(1.1)
                    Text("Loading report…")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Color.secondary)
                }
            } else {
                ScrollView {
                    VStack(spacing: 24) {

                        // MARK: - Time Range Picker
                        Picker("Range", selection: $timeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                        .onChange(of: timeRange) {
                            Task { await loadData() }
                        }

                        // MARK: - Summary Cards
                        HStack(spacing: 12) {
                            ReportStatCard(
                                value: "\(totalRepairs)",
                                label: "Total Repairs",
                                icon: "wrench.and.screwdriver.fill",
                                color: Color.brown
                            )
                            ReportStatCard(
                                value: String(format: "%.1f", averageDaily),
                                label: "Daily Avg",
                                icon: "chart.line.uptrend.xyaxis",
                                color: Color.blue
                            )
                            ReportStatCard(
                                value: bestDay.map { "\($0.count)" } ?? "—",
                                label: "Best Day",
                                icon: "star.fill",
                                color: Color.orange
                            )
                        }
                        .padding(.horizontal, 16)

                        // MARK: - Chart
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Daily Completed Repairs")
                                .font(.headline)
                                .foregroundStyle(Color.primary)

                            if repairData.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "chart.bar.xaxis")
                                        .font(.system(size: 40, weight: .light))
                                        .foregroundStyle(Color(.tertiaryLabel))
                                    Text("No repair data for this period")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 220)
                            } else {
                                Chart(repairData) { item in
                                    BarMark(
                                        x: .value("Day", item.shortDate),
                                        y: .value("Repairs", item.count)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.brown.opacity(0.7), Color.brown],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .cornerRadius(6)
                                    .annotation(position: .top, spacing: 4) {
                                        if item.count > 0 {
                                            Text("\(item.count)")
                                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                                .foregroundStyle(Color.brown)
                                        }
                                    }

                                    // Average line
                                    RuleMark(y: .value("Average", averageDaily))
                                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                                        .foregroundStyle(Color.orange.opacity(0.6))
                                        .annotation(position: .trailing, alignment: .trailing) {
                                            Text("avg")
                                                .font(.system(size: 9, weight: .semibold))
                                                .foregroundStyle(Color.orange)
                                        }
                                }
                                .chartYAxis {
                                    AxisMarks(position: .leading) { value in
                                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3]))
                                            .foregroundStyle(Color(.separator).opacity(0.3))
                                        AxisValueLabel()
                                            .font(.caption2)
                                            .foregroundStyle(Color(.tertiaryLabel))
                                    }
                                }
                                .chartXAxis {
                                    AxisMarks { value in
                                        AxisValueLabel()
                                            .font(.caption2)
                                            .foregroundStyle(Color(.tertiaryLabel))
                                    }
                                }
                                .frame(height: 220)
                            }
                        }
                        .padding(16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                        )
                        .padding(.horizontal, 16)

                        // MARK: - Daily Breakdown
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Daily Breakdown")
                                .font(.headline)
                                .foregroundStyle(Color.primary)

                            if repairData.isEmpty {
                                Text("No data available")
                                    .font(.subheadline)
                                    .foregroundStyle(Color(.tertiaryLabel))
                            } else {
                                ForEach(repairData.reversed()) { item in
                                    HStack(spacing: 14) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(item.count > 0 ? Color.brown.opacity(0.08) : Color(.tertiarySystemFill))
                                                .frame(width: 42, height: 42)
                                            Text(item.dayLabel)
                                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                                .foregroundStyle(item.count > 0 ? Color.brown : Color(.tertiaryLabel))
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.date.formatted(date: .abbreviated, time: .omitted))
                                                .font(.subheadline.weight(.medium))
                                                .foregroundStyle(Color.primary)
                                            Text("\(item.count) repair\(item.count == 1 ? "" : "s") completed")
                                                .font(.caption)
                                                .foregroundStyle(Color.secondary)
                                        }

                                        Spacer()

                                        Text("\(item.count)")
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                            .foregroundStyle(item.count > 0 ? Color.brown : Color(.tertiaryLabel))
                                    }

                                    if item.id != repairData.first?.id {
                                        Divider().background(Color(.separator))
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationTitle("Performance")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadData()
        }
    }

    // MARK: - Data Loading
    private func loadData() async {
        isLoading = true

        let days: Int
        switch timeRange {
        case .week:     days = 7
        case .twoWeeks: days = 14
        case .month:    days = 30
        }

        let cal = Calendar.current
        var dailyCounts: [Date: Int] = [:]

        // Initialize all days with 0
        for i in 0..<days {
            if let date = cal.date(byAdding: .day, value: -i, to: Date()) {
                dailyCounts[cal.startOfDay(for: date)] = 0
            }
        }

        // Fetch completed work orders
        do {
            let workOrders = try await WorkOrderService.fetchAllWorkOrders()
            let completed = workOrders.filter { $0.status == .completed }
            for wo in completed {
                if let createdAt = wo.createdAt {
                    let day = cal.startOfDay(for: createdAt)
                    if dailyCounts[day] != nil {
                        dailyCounts[day, default: 0] += 1
                    }
                }
            }
        } catch {
            print("[PerformanceReport] Error loading work orders: \(error)")
        }

        // Fetch completed tasks
        do {
            let tasks = try await MaintenanceTaskService.fetchAllTasks()
            let completed = tasks.filter { $0.status == .completed }
            for task in completed {
                if let scheduled = task.scheduledDate {
                    let day = cal.startOfDay(for: scheduled)
                    if dailyCounts[day] != nil {
                        dailyCounts[day, default: 0] += 1
                    }
                }
            }
        } catch {
            print("[PerformanceReport] Error loading tasks: \(error)")
        }

        // Sort by date ascending
        repairData = dailyCounts
            .map { DailyRepairData(date: $0.key, count: $0.value) }
            .sorted { $0.date < $1.date }

        isLoading = false
    }
}

// MARK: - Report Stat Card
private struct ReportStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(color.opacity(0.2), lineWidth: 0.8)
        )
    }
}
