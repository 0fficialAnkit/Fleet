import SwiftUI

struct VehiclesView: View {
    var viewModel: VehiclesViewModel
    @State private var complianceStore = ComplianceSettingsStore.shared

    var body: some View {
        Group {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if viewModel.vehicles.isEmpty && !viewModel.isLoading {
                    VStack(spacing: 12) {
                        Image(systemName: "truck.box")
                            .font(.system(size: 48))
                            .foregroundStyle(Color(.tertiaryLabel))
                        Text("No vehicles added yet")
                            .font(.headline)
                            .foregroundStyle(Color.secondary)
                        Text("Tap + to add your first vehicle")
                            .font(.subheadline)
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                } else {
                    ScrollView(showsIndicators: false) {

                        // ── Compliance Alert Banner ──────────────────────────────────
                        let nonCompliant = viewModel.vehicles.filter {
                            complianceStore.overallStatus(for: $0.licensePlate ?? $0.id.uuidString) == .nonCompliant
                        }
                        let expiringSoon = viewModel.vehicles.filter {
                            complianceStore.overallStatus(for: $0.licensePlate ?? $0.id.uuidString) == .expiringSoon
                        }

                        if !nonCompliant.isEmpty || !expiringSoon.isEmpty {
                            ComplianceAlertBanner(
                                nonCompliantCount: nonCompliant.count,
                                expiringSoonCount: expiringSoon.count
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        }

                        VStack(spacing: 12) {
                            ForEach(viewModel.vehicles) { vehicle in
                                let key = vehicle.licensePlate ?? vehicle.id.uuidString
                                NavigationLink(value: vehicle) {
                                    VehicleRowView(
                                        vehicle: vehicle,
                                        statusColor: viewModel.getStatusColor(vehicle.status),
                                        complianceStatus: complianceStore.overallStatus(for: key)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
    }
}

// MARK: - Compliance Alert Banner

struct ComplianceAlertBanner: View {
    let nonCompliantCount: Int
    let expiringSoonCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Fleet Compliance Alert")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
            }

            HStack(spacing: 16) {
                if nonCompliantCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                        Text("\(nonCompliantCount) Non-Compliant")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(Color(red: 1.0, green: 0.55, blue: 0.55))
                }

                if expiringSoonCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                        Text("\(expiringSoonCount) Expiring Soon")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.5))
                }
            }
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [
                    nonCompliantCount > 0
                        ? Color(red: 0.75, green: 0.15, blue: 0.15)
                        : Color(red: 0.7, green: 0.45, blue: 0.0),
                    nonCompliantCount > 0
                        ? Color(red: 0.55, green: 0.12, blue: 0.12)
                        : Color(red: 0.5, green: 0.32, blue: 0.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Vehicle Row View

struct VehicleRowView: View {
    let vehicle: Vehicle
    let statusColor: Color
    var complianceStatus: ComplianceStatus = .compliant

    var body: some View {
        HStack(spacing: 16) {

            // Vehicle icon with compliance colour ring
            ZStack {
                Circle()
                    .fill(Color.teal.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: "truck.box.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.teal)

                // Compliance indicator ring — only visible when not compliant
                if complianceStatus != .compliant {
                    Circle()
                        .stroke(complianceStatus.color, lineWidth: 2.5)
                        .frame(width: 48, height: 48)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(vehicle.make ?? "Unknown") \(vehicle.model ?? "")")
                    .font(.headline)
                    .foregroundColor(Color.primary)

                Text(vehicle.licensePlate ?? "No License Plate")
                    .font(.subheadline)
                    .foregroundColor(Color.secondary)

                // Compliance badge — shown only when not fully compliant
                if complianceStatus != .compliant {
                    ComplianceBadge(status: complianceStatus)
                        .padding(.top, 2)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                StatusBadge(
                    text: vehicle.status?.rawValue.capitalized ?? "Unknown",
                    color: statusColor
                )
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    complianceStatus == .nonCompliant
                        ? Color(red: 0.94, green: 0.27, blue: 0.27).opacity(0.35)
                        : complianceStatus == .expiringSoon
                            ? Color(red: 1.0, green: 0.62, blue: 0.04).opacity(0.3)
                            : Color.clear,
                    lineWidth: 1.2
                )
        )
    }
}

#Preview {
    NavigationStack {
        VehiclesView(viewModel: VehiclesViewModel())
    }
}
