import SwiftUI
import Charts

// MARK: - ViewModel

@MainActor
@Observable
final class FleetFuelAnalyticsViewModel {

    // MARK: Raw data
    private(set) var trips: [Trip] = []
    private(set) var fuelLogs: [FuelLog] = []

    var isLoading = false

    // MARK: Time span picker
    enum TimeSpan: String, CaseIterable, Identifiable {
        case week  = "Week"
        case month = "Month"
        case year  = "Year"
        var id: String { rawValue }
    }

    // MARK: - Computed: Trips (all vehicles)

    var completedTrips: [Trip] {
        trips.filter { $0.status == .completed }
    }

    var totalDistance: Double {
        completedTrips.reduce(0) { $0 + ($1.distance ?? 0) }
    }

    var totalTrips: Int { completedTrips.count }

    var avgDistancePerTrip: Double {
        guard totalTrips > 0 else { return 0 }
        return totalDistance / Double(totalTrips)
    }

    // MARK: - Computed: Fuel (all vehicles)

    var totalLiters: Double {
        fuelLogs.reduce(0) { $0 + ($1.litersUsed ?? 0) }
    }

    var totalFuelCost: Double {
        fuelLogs.reduce(0) { $0 + ($1.fuelCost ?? 0) }
    }

    var avgCostPerLitre: Double {
        guard totalLiters > 0 else { return 0 }
        return totalFuelCost / totalLiters
    }

    // MARK: - Chart data helpers

    struct ChartPoint: Identifiable {
        let id = UUID()
        let label: String
        let liters: Double
        let cost: Double
        let date: Date
    }

    func chartPoints(for span: TimeSpan) -> [ChartPoint] {
        let calendar = Calendar.current
        let now = Date()

        switch span {
        case .week:
            let startOfRange = calendar.date(byAdding: .day, value: -6, to: now)!
            let filtered = fuelLogs.filter { ($0.recordedAt ?? .distantPast) >= startOfRange }
            var dict: [Date: (Double, Double)] = [:]
            for log in filtered {
                guard let date = log.recordedAt else { continue }
                let day = calendar.startOfDay(for: date)
                let existing = dict[day] ?? (0, 0)
                dict[day] = (existing.0 + (log.litersUsed ?? 0),
                             existing.1 + (log.fuelCost ?? 0))
            }
            return (0...6).compactMap { offset -> ChartPoint? in
                let day = calendar.date(byAdding: .day, value: -6 + offset,
                                        to: calendar.startOfDay(for: now))!
                let label = day.formatted(.dateTime.weekday(.abbreviated))
                let values = dict[day] ?? (0, 0)
                return ChartPoint(label: label, liters: values.0, cost: values.1, date: day)
            }

        case .month:
            let startOfRange = calendar.date(byAdding: .weekOfYear, value: -3, to: now)!
            let filtered = fuelLogs.filter { ($0.recordedAt ?? .distantPast) >= startOfRange }
            var dict: [Int: (Double, Double, Date)] = [:]
            for log in filtered {
                guard let date = log.recordedAt else { continue }
                let week = calendar.component(.weekOfYear, from: date)
                let existing = dict[week] ?? (0, 0, date)
                dict[week] = (existing.0 + (log.litersUsed ?? 0),
                              existing.1 + (log.fuelCost ?? 0), date)
            }
            return dict.sorted { $0.value.2 < $1.value.2 }.enumerated().map { idx, pair in
                ChartPoint(label: "W\(idx + 1)", liters: pair.value.0,
                           cost: pair.value.1, date: pair.value.2)
            }

        case .year:
            let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now))!
            let filtered = fuelLogs.filter { ($0.recordedAt ?? .distantPast) >= startOfYear }
            var dict: [Int: (Double, Double, Date)] = [:]
            for log in filtered {
                guard let date = log.recordedAt else { continue }
                let month = calendar.component(.month, from: date)
                let existing = dict[month] ?? (0, 0, date)
                dict[month] = (existing.0 + (log.litersUsed ?? 0),
                               existing.1 + (log.fuelCost ?? 0), date)
            }
            return (1...12).compactMap { month -> ChartPoint? in
                let comps = DateComponents(year: calendar.component(.year, from: now), month: month)
                let date = calendar.date(from: comps) ?? now
                let label = date.formatted(.dateTime.month(.abbreviated))
                let values = dict[month] ?? (0, 0, date)
                return ChartPoint(label: label, liters: values.0, cost: values.1, date: values.2)
            }
        }
    }

    // MARK: - Distance chart

    struct DistancePoint: Identifiable {
        let id = UUID()
        let label: String
        let distance: Double
        let date: Date
    }

    func distancePoints(for span: TimeSpan) -> [DistancePoint] {
        let calendar = Calendar.current
        let now = Date()

        switch span {
        case .week:
            let startOfRange = calendar.date(byAdding: .day, value: -6, to: now)!
            let filtered = completedTrips.filter { ($0.startTime ?? .distantPast) >= startOfRange }
            var dict: [Date: Double] = [:]
            for trip in filtered {
                guard let date = trip.startTime else { continue }
                let day = calendar.startOfDay(for: date)
                dict[day] = (dict[day] ?? 0) + (trip.distance ?? 0)
            }
            return (0...6).map { offset in
                let day = calendar.date(byAdding: .day, value: -6 + offset,
                                        to: calendar.startOfDay(for: now))!
                return DistancePoint(label: day.formatted(.dateTime.weekday(.abbreviated)),
                                     distance: dict[day] ?? 0, date: day)
            }

        case .month:
            let startOfRange = calendar.date(byAdding: .weekOfYear, value: -3, to: now)!
            let filtered = completedTrips.filter { ($0.startTime ?? .distantPast) >= startOfRange }
            var dict: [Int: (Double, Date)] = [:]
            for trip in filtered {
                guard let date = trip.startTime else { continue }
                let week = calendar.component(.weekOfYear, from: date)
                let existing = dict[week] ?? (0, date)
                dict[week] = (existing.0 + (trip.distance ?? 0), date)
            }
            return dict.sorted { $0.value.1 < $1.value.1 }.enumerated().map { idx, pair in
                DistancePoint(label: "W\(idx + 1)", distance: pair.value.0, date: pair.value.1)
            }

        case .year:
            let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now))!
            let filtered = completedTrips.filter { ($0.startTime ?? .distantPast) >= startOfYear }
            var dict: [Int: (Double, Date)] = [:]
            for trip in filtered {
                guard let date = trip.startTime else { continue }
                let month = calendar.component(.month, from: date)
                let existing = dict[month] ?? (0, date)
                dict[month] = (existing.0 + (trip.distance ?? 0), date)
            }
            return (1...12).compactMap { month -> DistancePoint? in
                let comps = DateComponents(year: calendar.component(.year, from: now), month: month)
                let date = calendar.date(from: comps) ?? now
                let label = date.formatted(.dateTime.month(.abbreviated))
                let values = dict[month] ?? (0, date)
                return DistancePoint(label: label, distance: values.0, date: values.1)
            }
        }
    }

    // MARK: - Load (all vehicles, no driver filter)

    func loadData() async {
        isLoading = true
        async let t = TripService.fetchAllTrips()
        async let f = FuelLogService.fetchAllFuelLogs()
        trips    = (try? await t) ?? []
        fuelLogs = (try? await f) ?? []
        isLoading = false
    }
}

// MARK: - View

struct FleetFuelAnalyticsView: View {

    @State private var viewModel = FleetFuelAnalyticsViewModel()
    @State private var selectedSpan: FleetFuelAnalyticsViewModel.TimeSpan = .month
    @State private var showingFuelCost = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {

                // MARK: Time-span dropdown
                HStack {
                    Spacer()
                    Menu {
                        ForEach(FleetFuelAnalyticsViewModel.TimeSpan.allCases) { span in
                            Button {
                                selectedSpan = span
                            } label: {
                                HStack {
                                    Text(span.rawValue)
                                    if selectedSpan == span {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(selectedSpan.rawValue)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.primary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
                .padding(.horizontal, 16)

                // MARK: Stats row
                fleetStatsRow

                // MARK: Distance chart
                distanceChartCard

                // MARK: Fuel chart
                fuelChartCard

                // MARK: Cost breakdown
                costBreakdownCard
            }
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.4)
            }
        }
        .task { await viewModel.loadData() }
        .refreshable { await viewModel.loadData() }
    }

    // MARK: - Stats row

    private var fleetStatsRow: some View {
        HStack(spacing: 12) {
            FleetAnalyticsTile(
                value: String(format: "%.0f km", viewModel.totalDistance),
                label: "Total Distance",
                icon: "road.lanes",
                tint: .blue
            )
            FleetAnalyticsTile(
                value: "\(viewModel.totalTrips)",
                label: "Completed Trips",
                icon: "checkmark.seal.fill",
                tint: .green
            )
            FleetAnalyticsTile(
                value: String(format: "%.1f L", viewModel.totalLiters),
                label: "Fuel Used",
                icon: "drop.fill",
                tint: .orange
            )
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Distance chart card

    private var distanceChartCard: some View {
        let points = viewModel.distancePoints(for: selectedSpan)
        let allZero = points.allSatisfy { $0.distance == 0 }

        return FleetChartCard(title: "Distance Driven", subtitle: "km per period — all vehicles",
                              icon: "road.lanes", tint: .blue) {
            if allZero {
                fleetEmptyChart
            } else {
                Chart(points) { point in
                    BarMark(
                        x: .value("Period", point.label),
                        y: .value("km", point.distance)
                    )
                    .foregroundStyle(
                        LinearGradient(colors: [.blue, .blue.opacity(0.45)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .cornerRadius(6)
                    .annotation(position: .top) {
                        if point.distance > 0 {
                            Text(String(format: "%.0f", point.distance))
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(Color(.separator))
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(String(format: "%.0f", v))
                                    .font(.caption2).foregroundStyle(Color.secondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label).font(.caption2).foregroundStyle(Color.secondary)
                            }
                        }
                    }
                }
                .frame(height: 180)
            }
        }
    }

    // MARK: - Fuel chart card

    private var fuelChartCard: some View {
        let points = viewModel.chartPoints(for: selectedSpan)
        let allZero = points.allSatisfy { $0.liters == 0 }

        return FleetChartCard(
            title: showingFuelCost ? "Fuel Spend" : "Fuel Consumed",
            subtitle: (showingFuelCost ? "₹ per period" : "litres per period") + " — all vehicles",
            icon: "drop.fill",
            tint: .orange,
            trailing: {
                AnyView(
                    Toggle(isOn: $showingFuelCost.animation(.easeInOut(duration: 0.25))) {
                        Label("Cost", systemImage: "indianrupeesign.circle")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.secondary)
                            .labelStyle(.iconOnly)
                    }
                    .toggleStyle(.button)
                    .tint(Color.orange)
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                )
            }
        ) {
            if allZero {
                fleetEmptyChart
            } else {
                Chart(points) { point in
                    if showingFuelCost {
                        BarMark(x: .value("Period", point.label), y: .value("₹", point.cost))
                            .foregroundStyle(LinearGradient(
                                colors: [.orange, .orange.opacity(0.4)],
                                startPoint: .top, endPoint: .bottom))
                            .cornerRadius(6)
                            .annotation(position: .top) {
                                if point.cost > 0 {
                                    Text("₹\(Int(point.cost))")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                    } else {
                        BarMark(x: .value("Period", point.label), y: .value("L", point.liters))
                            .foregroundStyle(LinearGradient(
                                colors: [.orange, .orange.opacity(0.4)],
                                startPoint: .top, endPoint: .bottom))
                            .cornerRadius(6)
                            .annotation(position: .top) {
                                if point.liters > 0 {
                                    Text(String(format: "%.1fL", point.liters))
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(Color(.separator))
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(showingFuelCost ? "₹\(Int(v))" : String(format: "%.0fL", v))
                                    .font(.caption2).foregroundStyle(Color.secondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label).font(.caption2).foregroundStyle(Color.secondary)
                            }
                        }
                    }
                }
                .frame(height: 180)
            }
        }
    }

    // MARK: - Cost breakdown card

    private var costBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Fleet Cost Breakdown", systemImage: "indianrupeesign.circle.fill")
                .font(.headline)
                .foregroundStyle(Color.primary)

            Divider()

            fleetInfoRow(label: "Total Fuel Cost",
                         value: "₹\(Int(viewModel.totalFuelCost))",
                         icon: "fuelpump.fill", tint: .orange)
            fleetInfoRow(label: "Total Liters",
                         value: String(format: "%.1f L", viewModel.totalLiters),
                         icon: "drop.fill", tint: .blue)
            fleetInfoRow(label: "Avg ₹ / Litre",
                         value: String(format: "₹%.2f", viewModel.avgCostPerLitre),
                         icon: "chart.line.uptrend.xyaxis", tint: .purple)
            fleetInfoRow(label: "Avg Distance / Trip",
                         value: String(format: "%.1f km", viewModel.avgDistancePerTrip),
                         icon: "road.lanes.curved.right", tint: .teal)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
    }

    private func fleetInfoRow(label: String, value: String, icon: String, tint: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 28)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.primary)
        }
    }

    // MARK: - Empty state

    private var fleetEmptyChart: some View {
        ContentUnavailableView {
            Label("No Data", systemImage: "chart.bar.xaxis")
        } description: {
            Text("No records found for this period.")
        }
        .frame(height: 160)
    }
}

// MARK: - Reusable sub-views (fleet-scoped to avoid naming collisions)

private struct FleetAnalyticsTile: View {
    let value: String
    let label: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct FleetChartCard<Content: View, Trailing: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let trailing: () -> Trailing
    @ViewBuilder let content: () -> Content

    init(title: String, subtitle: String, icon: String, tint: Color,
         trailing: @escaping () -> Trailing = { EmptyView() },
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title; self.subtitle = subtitle
        self.icon = icon;   self.tint = tint
        self.trailing = trailing; self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(tint)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(title).font(.headline).foregroundStyle(Color.primary)
                        Text(subtitle).font(.caption).foregroundStyle(Color.secondary)
                    }
                }
                Spacer()
                trailing()
            }
            content()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
    }
}

extension FleetChartCard where Trailing == EmptyView {
    init(title: String, subtitle: String, icon: String, tint: Color,
         @ViewBuilder content: @escaping () -> Content) {
        self.init(title: title, subtitle: subtitle, icon: icon, tint: tint,
                  trailing: { EmptyView() }, content: content)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FleetFuelAnalyticsView()
    }
}
