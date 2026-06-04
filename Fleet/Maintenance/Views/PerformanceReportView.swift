import SwiftUI
import Charts

// MARK: - Daily Repair Data Point
struct DailyRepairData: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int

    var dayLabel: String {
        let f = DateFormatter(); f.dateFormat = "EEE"; return f.string(from: date)
    }
    var shortDate: String {
        let f = DateFormatter(); f.dateFormat = "dd MMM"; return f.string(from: date)
    }
}

// MARK: - Performance Report View
struct PerformanceReportView: View {
    @State private var repairData: [DailyRepairData] = []
    @State private var isLoading  = false
    @State private var timeRange: TimeRange = .week

    enum TimeRange: String, CaseIterable {
        case week     = "7 Days"
        case twoWeeks = "14 Days"
        case month    = "30 Days"
    }

    var totalRepairs: Int    { repairData.reduce(0) { $0 + $1.count } }
    var averageDaily: Double { repairData.isEmpty ? 0 : Double(totalRepairs) / Double(repairData.count) }
    var bestDay: DailyRepairData? { repairData.max(by: { $0.count < $1.count }) }

    var body: some View {
        Group {
            if isLoading && repairData.isEmpty {
                ProgressView().tint(.brown)
            } else {
                List {
                    // ── Time range picker ────────────────────────────────
                    Section {
                        Picker("Range", selection: $timeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .onChange(of: timeRange) { Task { await loadData() } }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    // ── KPI summary ──────────────────────────────────────
                    Section {
                        HStack(spacing: 0) {
                            repKpi("\(totalRepairs)", "Total Repairs",   .brown)
                            Divider().frame(height: 36)
                            repKpi(String(format: "%.1f", averageDaily), "Daily Avg", .blue)
                            Divider().frame(height: 36)
                            repKpi(bestDay.map { "\($0.count)" } ?? "—", "Best Day",  .orange)
                        }
                        .padding(.vertical, 4)
                    }

                    // ── Chart ────────────────────────────────────────────
                    Section("Daily Completed Repairs") {
                        if repairData.isEmpty {
                            ContentUnavailableView(
                                "No Data",
                                systemImage: "chart.bar.xaxis",
                                description: Text("No repair data for this period.")
                            )
                            .listRowBackground(Color.clear)
                        } else {
                            Chart(repairData) { item in
                                BarMark(
                                    x: .value("Day", item.shortDate),
                                    y: .value("Repairs", item.count)
                                )
                                .foregroundStyle(Color.brown.gradient)
                                .cornerRadius(5)
                                .annotation(position: .top, spacing: 4) {
                                    if item.count > 0 {
                                        Text("\(item.count)")
                                            .font(.caption2.bold())
                                            .foregroundStyle(Color.brown)
                                    }
                                }

                                RuleMark(y: .value("Average", averageDaily))
                                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                                    .foregroundStyle(Color.orange.opacity(0.7))
                                    .annotation(position: .trailing, alignment: .trailing) {
                                        Text("avg")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(Color.orange)
                                    }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading) { _ in
                                    AxisGridLine()
                                    AxisValueLabel().font(.caption2).foregroundStyle(Color(.tertiaryLabel))
                                }
                            }
                            .chartXAxis {
                                AxisMarks { _ in
                                    AxisValueLabel().font(.caption2).foregroundStyle(Color(.tertiaryLabel))
                                }
                            }
                            .frame(height: 200)
                            .padding(.vertical, 8)
                        }
                    }

                    // ── Daily breakdown ──────────────────────────────────
                    if !repairData.isEmpty {
                        Section("Daily Breakdown") {
                            ForEach(repairData.reversed()) { item in
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(item.count > 0 ? Color.brown.opacity(0.1) : Color(.tertiarySystemFill))
                                            .frame(width: 40, height: 40)
                                        Text(item.dayLabel)
                                            .font(.caption.bold())
                                            .foregroundStyle(item.count > 0 ? Color.brown : Color(.tertiaryLabel))
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.date.formatted(date: .abbreviated, time: .omitted))
                                            .font(.subheadline.weight(.medium))
                                        Text("\(item.count) repair\(item.count == 1 ? "" : "s") completed")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Text("\(item.count)")
                                        .font(.title2.bold())
                                        .foregroundStyle(item.count > 0 ? Color.brown : Color(.tertiaryLabel))
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable { await loadData() }
            }
        }
        .navigationTitle("Performance")
        .navigationBarTitleDisplayMode(.large)
        .task { await loadData() }
    }

    // MARK: - KPI cell
    private func repKpi(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.bold()).foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Data Loading (no logic change)
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
        for i in 0..<days {
            if let date = cal.date(byAdding: .day, value: -i, to: Date()) {
                dailyCounts[cal.startOfDay(for: date)] = 0
            }
        }
        do {
            let workOrders = try await WorkOrderService.fetchAllWorkOrders()
            for wo in workOrders.filter({ $0.status == .completed }) {
                if let d = wo.createdAt {
                    let day = cal.startOfDay(for: d)
                    if dailyCounts[day] != nil { dailyCounts[day, default: 0] += 1 }
                }
            }
        } catch { print("[PerformanceReport] WO error: \(error)") }
        do {
            let tasks = try await MaintenanceTaskService.fetchAllTasks()
            for task in tasks.filter({ $0.status == .completed }) {
                if let d = task.scheduledDate {
                    let day = cal.startOfDay(for: d)
                    if dailyCounts[day] != nil { dailyCounts[day, default: 0] += 1 }
                }
            }
        } catch { print("[PerformanceReport] Task error: \(error)") }
        repairData = dailyCounts.map { DailyRepairData(date: $0.key, count: $0.value) }
            .sorted { $0.date < $1.date }
        isLoading = false
    }
}
