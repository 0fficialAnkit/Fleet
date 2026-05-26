import SwiftUI

struct DriverVehicleDetailView: View {
    let vehicle: Vehicle

    @State private var navigateToReport = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // MARK: - Hero Header
                    vehicleHeroHeader

                    // MARK: - Status Chips
                    statusChipsRow

                    // MARK: - Vehicle Info Card
                    vehicleInfoCard

                    // MARK: - Health Card
                    vehicleHealthCard

                    // MARK: - Report Issue Button
                    reportIssueButton
                }
                .padding(16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Vehicle Details")
        .navigationBarTitleDisplayMode(.inline)
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
                color: vehicle.status == .active ? Color.green : Color.yellow,
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
                InfoRow(icon: "building.2", label: "Manufacturer", value: vehicle.make ?? "N/A")
                Divider().background(Color(.separator))
                InfoRow(icon: "tag", label: "Model", value: vehicle.model ?? "N/A")
                Divider().background(Color(.separator))
                InfoRow(icon: "calendar", label: "Year", value: vehicle.year.map(String.init) ?? "N/A")
                Divider().background(Color(.separator))
                InfoRow(
                    icon: "fuelpump",
                    label: "Tank Capacity",
                    value: vehicle.tankCapacity.map { String(format: "%.1f L", $0) } ?? "N/A"
                )
                if let vin = vehicle.vin {
                    Divider().background(Color(.separator))
                    InfoRow(icon: "qrcode", label: "VIN", value: vin)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            )

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
                    label: "km/l Economy",
                    color: Color.green
                )
                statCard(
                    icon: "fuelpump.fill",
                    value: "72%",
                    label: "Fuel Level",
                    color: Color.green
                )
            }
        }
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
                .font(.footnote)
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
        )

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
                        .font(.footnote)
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

        }
        .buttonStyle(.plain)
    }
}
