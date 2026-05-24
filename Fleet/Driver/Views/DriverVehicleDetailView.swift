import SwiftUI

struct DriverVehicleDetailView: View {
    let vehicle: Vehicle

    @State private var navigateToReport = false

    var body: some View {
        ZStack {
            themeModel.backgroundPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: themeModel.spacingLG) {

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
                .padding(themeModel.spacingMD)
                .padding(.bottom, themeModel.spacingXXL)
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
        VStack(spacing: themeModel.spacingMD) {
            ZStack {
                Circle()
                    .fill(themeModel.driverPrimary.opacity(0.12))
                    .frame(width: 110, height: 110)
                Circle()
                    .fill(themeModel.driverPrimary.opacity(0.06))
                    .frame(width: 140, height: 140)
                Image(systemName: "truck.box.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(themeModel.driverPrimary)
            }
            .padding(.top, themeModel.spacingSM)

            VStack(spacing: 6) {
                Text("\(vehicle.make ?? "Unknown") \(vehicle.model ?? "")")
                    .font(themeModel.largeTitle(26))
                    .foregroundStyle(themeModel.textPrimary)

                Text(vehicle.licensePlate ?? "—")
                    .font(themeModel.bodyMedium())
                    .foregroundStyle(themeModel.driverPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(themeModel.driverPrimary.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Status Chips Row
    private var statusChipsRow: some View {
        HStack(spacing: themeModel.spacingSM) {
            StatusBadge(
                text: vehicle.status?.rawValue.capitalized ?? "Unknown",
                color: vehicle.status == .active ? themeModel.success : themeModel.warning,
                icon: vehicle.status == .active ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
            )

            if let year = vehicle.year {
                StatusBadge(text: String(year), color: themeModel.info, icon: "calendar")
            }

            Spacer()
        }
    }

    // MARK: - Vehicle Info Card
    private var vehicleInfoCard: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
            Label("Vehicle Info", systemImage: "info.circle.fill")
                .font(themeModel.headline())
                .foregroundStyle(themeModel.textPrimary)

            VStack(spacing: 0) {
                InfoRow(icon: "building.2", label: "Manufacturer", value: vehicle.make ?? "N/A")
                Divider().background(themeModel.divider)
                InfoRow(icon: "tag", label: "Model", value: vehicle.model ?? "N/A")
                Divider().background(themeModel.divider)
                InfoRow(icon: "calendar", label: "Year", value: vehicle.year.map(String.init) ?? "N/A")
                Divider().background(themeModel.divider)
                InfoRow(
                    icon: "fuelpump",
                    label: "Tank Capacity",
                    value: vehicle.tankCapacity.map { String(format: "%.1f L", $0) } ?? "N/A"
                )
                if let vin = vehicle.vin {
                    Divider().background(themeModel.divider)
                    InfoRow(icon: "qrcode", label: "VIN", value: vin)
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

    // MARK: - Health Card
    private var vehicleHealthCard: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
            Label("Quick Stats", systemImage: "heart.text.clipboard.fill")
                .font(themeModel.headline())
                .foregroundStyle(themeModel.textPrimary)

            HStack(spacing: themeModel.spacingMD) {
                statCard(
                    icon: "gauge.open.with.lines.needle.33percent",
                    value: vehicle.mileage.map { String(format: "%.1f", $0) } ?? "—",
                    label: "km/l Economy",
                    color: themeModel.success
                )
                statCard(
                    icon: "fuelpump.fill",
                    value: "72%",
                    label: "Fuel Level",
                    color: themeModel.driverPrimary
                )
            }
        }
    }

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: themeModel.spacingSM) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusXS, style: .continuous))

            Text(value)
                .font(themeModel.title(22))
                .foregroundStyle(themeModel.textPrimary)

            Text(label)
                .font(themeModel.caption())
                .foregroundStyle(themeModel.textTertiary)
        }
        .padding(themeModel.spacingMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
        )
        .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
    }

    // MARK: - Report Issue Button
    private var reportIssueButton: some View {
        Button(action: { navigateToReport = true }) {
            HStack(spacing: themeModel.spacingMD) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 18, weight: .semibold))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Report an Issue")
                        .font(themeModel.bodyMedium())
                        .fontWeight(.semibold)
                    Text("Notify maintenance about a problem")
                        .font(themeModel.caption())
                        .opacity(0.75)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .opacity(0.7)
            }
            .foregroundStyle(.white)
            .padding(themeModel.spacingMD)
            .background(
                LinearGradient(
                    colors: [themeModel.danger, themeModel.danger.opacity(0.75)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
            .shadow(color: themeModel.danger.opacity(0.35), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }
}


