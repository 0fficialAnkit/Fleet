import SwiftUI

enum UsageTimePeriod: String, CaseIterable, Identifiable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case custom = "Custom"
    var id: String { rawValue }
}

struct UsageReportView: View {
    let vehicle: Vehicle
    let viewModel: VehiclesViewModel
    
    @State private var selectedPeriod: UsageTimePeriod = .weekly
    @State private var customStartDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var customEndDate = Date()
    
    var dateRange: (start: Date, end: Date) {
        let now = Date()
        let calendar = Calendar.current
        switch selectedPeriod {
        case .daily:
            let start = calendar.startOfDay(for: now)
            return (start, now)
        case .weekly:
            let start = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return (start, now)
        case .monthly:
            let start = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return (start, now)
        case .custom:
            // Ensure end date is end of day
            let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: customEndDate) ?? customEndDate
            let start = calendar.startOfDay(for: customStartDate)
            return (start, end)
        }
    }
    
    var periodDays: Double {
        let interval = dateRange.end.timeIntervalSince(dateRange.start)
        return max(1.0, interval / 86400.0) // At least 1 day to avoid div by zero
    }
    
    var periodTrips: [Trip] {
        viewModel.getTripsForUsage(vehicleId: vehicle.id, startDate: dateRange.start, endDate: dateRange.end)
    }
    
    var totalDistance: Double {
        viewModel.calculateTotalDistance(trips: periodTrips)
    }
    
    var totalTripsCount: Int {
        periodTrips.count
    }
    
    var idleTimeHours: Double {
        viewModel.calculateIdleTimeHours(trips: periodTrips, startDate: dateRange.start, endDate: dateRange.end)
    }
    
    var insight: (status: String, description: String, color: Color) {
        viewModel.generateUsageInsight(distance: totalDistance, tripsCount: totalTripsCount, idleHours: idleTimeHours, periodDays: periodDays)
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // Vehicle Header
                    VStack(spacing: 6) {
                        Text("\(vehicle.make ?? "Unknown") \(vehicle.model ?? "")")
                            .font(.title2.bold())
                            .foregroundColor(Color.primary)
                        
                        Text(vehicle.licensePlate ?? "NO PLATE")
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color.teal)
                    }
                    .padding(.top, 16)
                    
                    // Filter Section
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Time Period")
                        
                        Picker("Time Period", selection: $selectedPeriod) {
                            ForEach(UsageTimePeriod.allCases) { period in
                                Text(period.rawValue).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        if selectedPeriod == .custom {
                            HStack {
                                DatePicker("Start", selection: $customStartDate, displayedComponents: .date)
                                    .labelsHidden()
                                Text("to")
                                    .foregroundColor(.secondary)
                                DatePicker("End", selection: $customEndDate, displayedComponents: .date)
                                    .labelsHidden()
                                Spacer()
                            }
                            .padding(.top, 8)
                        } else {
                            Text("\(dateRange.start.formatted(date: .abbreviated, time: .omitted)) - \(dateRange.end.formatted(date: .abbreviated, time: .omitted))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 16)
                    
                    // Key Metrics
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Usage Metrics")
                            .padding(.horizontal, 16)
                        
                        HStack(spacing: 12) {
                            UsageMetricCard(
                                title: "Distance",
                                value: String(format: "%.0f", totalDistance),
                                unit: "km",
                                icon: "ruler.fill",
                                color: .blue
                            )
                            
                            UsageMetricCard(
                                title: "Trips",
                                value: "\(totalTripsCount)",
                                unit: "",
                                icon: "map.fill",
                                color: .purple
                            )
                        }
                        .padding(.horizontal, 16)
                        
                        // Idle time removed per user request
                    }
                    
                    // Insights
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "AI Insight")
                            .padding(.horizontal, 16)
                        
                        HStack(spacing: 16) {
                            Image(systemName: insight.status == "Overused" ? "flame.fill" : (insight.status == "Underused" ? "leaf.fill" : "checkmark.seal.fill"))
                                .font(.system(size: 28))
                                .foregroundColor(insight.color)
                                .frame(width: 44, height: 44)
                                .background(insight.color.opacity(0.15))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(insight.status)
                                    .font(.headline)
                                    .foregroundColor(insight.color)
                                Text(insight.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                        }
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(insight.color.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                    }
                    
                    // Maintenance History
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            SectionHeader(title: "Maintenance History")
                            Spacer()
                            Text("3 repairs")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, 16)
                        
                        VStack(spacing: 0) {
                            // Dummy Record 1
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Engine Oil Replacement")
                                        .font(.body.weight(.medium))
                                        .foregroundColor(.primary)
                                    Text((Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()).formatted(date: .abbreviated, time: .omitted))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "wrench.and.screwdriver.fill")
                                    .foregroundColor(Color.orange)
                            }
                            .padding(16)
                            
                            Divider().padding(.leading, 16)
                            
                            // Dummy Record 2
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Brake Pads Changed")
                                        .font(.body.weight(.medium))
                                        .foregroundColor(.primary)
                                    Text((Calendar.current.date(byAdding: .day, value: -45, to: Date()) ?? Date()).formatted(date: .abbreviated, time: .omitted))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "wrench.and.screwdriver.fill")
                                    .foregroundColor(Color.orange)
                            }
                            .padding(16)
                            
                            Divider().padding(.leading, 16)
                            
                            // Dummy Record 3
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Tire Rotation")
                                        .font(.body.weight(.medium))
                                        .foregroundColor(.primary)
                                    Text((Calendar.current.date(byAdding: .day, value: -120, to: Date()) ?? Date()).formatted(date: .abbreviated, time: .omitted))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "wrench.and.screwdriver.fill")
                                    .foregroundColor(Color.orange)
                            }
                            .padding(16)
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal, 16)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle("Usage Report")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Subcomponents

struct UsageMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(.secondaryLabel))
                Spacer()
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color.primary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        UsageReportView(
            vehicle: Vehicle(id: UUID(), make: "Ford", model: "Transit", licensePlate: "CA-123", status: .active, vehicleType: .car),
            viewModel: VehiclesViewModel()
        )
    }
}
