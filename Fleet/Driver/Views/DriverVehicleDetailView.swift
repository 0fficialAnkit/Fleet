import SwiftUI

struct DriverVehicleDetailView: View {
    let vehicle: Vehicle

    @State private var navigateToReport = false
    @State private var totalKmTravelled: Double = 0
    @State private var maintenanceHistory: [MaintenanceHistory] = []

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // MARK: - Hero Header
                    vehicleHeroHeader

                    // MARK: - Status Chips
                    statusChipsRow

                    // MARK: - Vehicle Info Card
                    vehicleInfoCard

                    // MARK: - Compliance
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Compliance", systemImage: "shield.lefthalf.filled")
                            .font(.headline)
                            .foregroundStyle(Color.primary)
                        VehicleComplianceSection(vehicle: vehicle, editable: false)
                    }

                    // MARK: - Health Card
                    vehicleHealthCard

                    // MARK: - Maintenance History
                    maintenanceHistoryCard

                    // MARK: - Report Issue Button
                    reportIssueButton
                }
                .padding(16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Vehicle Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Total km from all completed trips for this vehicle
            let trips = (try? await TripService.fetchTripsForVehicle(vehicleId: vehicle.id)) ?? []
            totalKmTravelled = trips
                .filter { $0.status == .completed }
                .compactMap { $0.distance }
                .reduce(0, +)

            // Maintenance history for this vehicle
            let all = (try? await MaintenanceHistoryService.fetchAllHistory()) ?? []
            maintenanceHistory = all
                .filter { $0.vehicleId == vehicle.id }
                .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
        }
        .navigationDestination(isPresented: $navigateToReport) {
            DriverReportIssueView(vehicle: vehicle)
        }
    }

    // MARK: - Hero Header
    private var vehicleHeroHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 110, height: 110)
                Circle()
                    .fill(Color.green.opacity(0.06))
                    .frame(width: 140, height: 140)
                Image(systemName: "truck.box.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.green)
            }
            .padding(.top, 8)

            VStack(spacing: 6) {
                Text("\(vehicle.make ?? "Unknown") \(vehicle.model ?? "")")
                    .font(.title2.bold())
                    .foregroundStyle(Color.primary)

                Text(vehicle.licensePlate ?? "—")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.green)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(Color.green.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Status Chips Row
    private var statusChipsRow: some View {
        HStack(spacing: 8) {
            StatusBadge(
                text: vehicle.status?.rawValue.capitalized ?? "Unknown",
                color: vehicle.status == .active ? Color.green : Color.orange,
                icon: vehicle.status == .active ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
            )

            if let year = vehicle.year {
                StatusBadge(text: String(year), color: Color.blue, icon: "calendar")
            }

            Spacer()
        }
    }

    // MARK: - Vehicle Info Card
    private var vehicleInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Vehicle Info", systemImage: "info.circle.fill")
                .font(.headline)
                .foregroundStyle(Color.primary)

            VStack(spacing: 0) {
                InfoRow(icon: "building.2", label: "Manufacturer",
                        value: vehicle.make ?? "N/A")
                Divider().background(Color(UIColor.separator))
                InfoRow(icon: "tag", label: "Model",
                        value: vehicle.model ?? "N/A")
                Divider().background(Color(UIColor.separator))
                InfoRow(icon: "calendar", label: "Year",
                        value: vehicle.year.map(String.init) ?? "N/A")
                Divider().background(Color(UIColor.separator))
                InfoRow(icon: "fuelpump", label: "Tank Capacity",
                        value: vehicle.tankCapacity.map { String(format: "%.1f L", $0) } ?? "N/A")
                Divider().background(Color(UIColor.separator))
                InfoRow(icon: "gauge.open.with.lines.needle.33percent", label: "Fuel Economy",
                        value: vehicle.mileage.map { String(format: "%.1f km/L", $0) } ?? "N/A")
                Divider().background(Color(UIColor.separator))
                InfoRow(icon: "creditcard", label: "Purchase Date",
                        value: vehicle.purchaseDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")
                Divider().background(Color(UIColor.separator))
                InfoRow(icon: "road.lanes", label: "Total km Travelled",
                        value: totalKmTravelled > 0 ? String(format: "%.1f km", totalKmTravelled) : "No trips yet")
                if let type = vehicle.vehicleType {
                    Divider().background(Color(UIColor.separator))
                    InfoRow(icon: "car.fill", label: "Vehicle Type",
                            value: type.displayName)
                }
                if let vin = vehicle.vin, !vin.isEmpty {
                    Divider().background(Color(UIColor.separator))
                    InfoRow(icon: "qrcode", label: "VIN", value: vin)
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - Health Card
    private var vehicleHealthCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Quick Stats", systemImage: "heart.text.clipboard.fill")
                .font(.headline)
                .foregroundStyle(Color.primary)

            HStack(spacing: 16) {
                statCard(
                    icon: "gauge.open.with.lines.needle.33percent",
                    value: vehicle.mileage.map { String(format: "%.1f", $0) } ?? "—",
                    label: "km/L Economy",
                    color: Color.green
                )
                statCard(
                    icon: "road.lanes",
                    value: totalKmTravelled > 0 ? String(format: "%.0f", totalKmTravelled) : "0",
                    label: "km Total",
                    color: Color.blue
                )
            }
        }
    }

    // MARK: - Maintenance History Card
    private var maintenanceHistoryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Maintenance History", systemImage: "wrench.and.screwdriver.fill")
                .font(.headline)
                .foregroundStyle(Color.primary)

            if maintenanceHistory.isEmpty {
                Text("No maintenance records yet.")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(maintenanceHistory.prefix(5).enumerated()), id: \.element.id) { idx, record in
                        if idx > 0 { Divider().background(Color(UIColor.separator)) }
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(record.serviceDetails ?? "Service completed")
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(2)
                                if let date = record.completedAt {
                                    Text(date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption)
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                            Spacer()
                            if let cost = record.cost {
                                Text("₹\(Int(cost))")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.green)
                            }
                        }
                        .padding(.vertical, 10)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(value)
                .font(.title3.bold())
                .foregroundStyle(Color.primary)

            Text(label)
                .font(.body)
                .foregroundStyle(Color(UIColor.tertiaryLabel))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Report Issue Button
    private var reportIssueButton: some View {
        Button(action: { navigateToReport = true }) {
            HStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 18, weight: .semibold))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Report an Issue")
                        .font(.body.weight(.medium))
                        .fontWeight(.semibold)
                    Text("Notify maintenance about a problem")
                        .font(.body)
                        .opacity(0.75)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .opacity(0.7)
            }
            .foregroundStyle(.white)
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color.red, Color.red.opacity(0.75)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.red.opacity(0.35), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }
}


