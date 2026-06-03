import SwiftUI

struct OrderDetailView: View {
    let trip: Trip
    let viewModel: OrdersViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var voiceLogs: [VoiceTripLog] = []

    var route: Route? {
        viewModel.route(for: trip.routeId)
    }

    var driverName: String {
        viewModel.driverName(for: trip.driverId)
    }

    var vehicleInfo: String {
        viewModel.vehicleName(for: trip.vehicleId)
    }

    var formattedDate: String {
        guard let date = trip.startTime else { return "Not Scheduled" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var orderIcon: String {
        switch trip.orderType {
        case .bulkOrderShip: return "shippingbox.fill"
        case .pickUpAndDrop: return "arrow.left.arrow.right"
        case .travel: return "car.fill"
        case .none: return "shippingbox"
        }
    }

    var orderColor: Color {
        switch trip.orderType {
        case .bulkOrderShip: return Color.brown
        case .pickUpAndDrop: return Color.teal
        case .travel: return Color.green
        case .none: return Color(.tertiaryLabel)
        }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(orderColor.opacity(0.15))
                                .frame(width: 110, height: 110)

                            Image(systemName: orderIcon)
                                .font(.system(size: 44))
                                .foregroundStyle(orderColor)
                        }
                        .padding(.bottom, 8)

                        Text(route?.routeName ?? "Unknown Route")
                            .font(.title3.bold())
                            .foregroundStyle(Color.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)

                        StatusBadge(text: trip.status?.rawValue.capitalized ?? "Unknown", color: viewModel.getStatusColor(for: trip.status))
                    }
                    .padding(.top, 32)

                    // Information Cards
                    VStack(spacing: 16) {
                        OrderDetailInfoRow(icon: "number", title: "Order ID", value: "#\(trip.id.uuidString.prefix(8).uppercased())")

                        Divider().background(Color(.separator))
                        OrderDetailInfoRow(icon: "shippingbox.fill", title: "Order Type", value: trip.orderType?.displayName ?? "N/A")

                        Divider().background(Color(.separator))
                        OrderDetailInfoRow(icon: "mappin.and.ellipse", title: "Destination", value: route?.endLocation ?? "N/A")

                        Divider().background(Color(.separator))
                        OrderDetailInfoRow(icon: "calendar", title: "Start Date", value: formattedDate)

                        Divider().background(Color(.separator))
                        OrderDetailInfoRow(icon: "person.crop.circle.fill", title: "Driver", value: driverName)

                        Divider().background(Color(.separator))
                        OrderDetailInfoRow(icon: "car.fill", title: "Vehicle", value: vehicleInfo)
                    }
//                    .padding(16)
//                    .background(Color(.systemBackground))
//                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
//                    .padding(.horizontal, 16)
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 16)

                    if !voiceLogs.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Driver Voice Logs")
                                    .font(.headline)
                                    .foregroundStyle(Color.primary)
                                Spacer()
                                Text("\(voiceLogs.count) updates")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondary)
                            }
                            .padding(.horizontal, 4)

                            ForEach(voiceLogs) { log in
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "mic.fill")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.purple)
                                        Text("Voice Update")
                                            .font(.subheadline.bold())
                                            .foregroundStyle(Color.primary)
                                        Spacer()
                                        if let date = log.createdAt {
                                            Text(date.formatted(date: .omitted, time: .shortened))
                                                .font(.caption)
                                                .foregroundStyle(Color.secondary)
                                        }
                                    }

                                    // Extracted facts row
                                    let status = log.voiceLogStatus
                                    let location = log.extractedLocation
                                    let mileage = log.extractedMileage
                                    let eta = log.extractedETA

                                    if status != nil || location != nil || mileage != nil || eta != nil {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 8) {
                                                if let status = status {
                                                    FactChip(icon: status.icon, text: status.displayName, color: statusColor(for: status))
                                                }
                                                if let location = location {
                                                    FactChip(icon: "mappin.and.ellipse", text: location, color: .blue)
                                                }
                                                if let mileage = mileage {
                                                    FactChip(icon: "road.lanes", text: "\(String(format: "%.1f", mileage)) km", color: .green)
                                                }
                                                if let eta = eta {
                                                    FactChip(icon: "clock", text: eta, color: .orange)
                                                }
                                            }
                                        }
                                    }

                                    Text("\"\(log.transcription)\"")
                                        .font(.body)
                                        .italic()
                                        .foregroundStyle(Color.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(16)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
        .navigationTitle("Order Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive, action: {
                        Task {
                            do {
                                try await viewModel.deleteTrip(trip)
                                await MainActor.run { dismiss() }
                            } catch {
                                // You may want to surface this error to the user in the future
                                print("Failed to delete trip: \(error)")
                            }
                        }
                    }) {
                        Label("Delete Order", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .task {
            await loadVoiceLogs()
            RealtimeManager.shared.addVoiceTripLogsChangeHandler {
                Task {
                    await loadVoiceLogs()
                }
            }
        }
    }

    private func loadVoiceLogs() async {
        do {
            voiceLogs = try await VoiceTripLogService.fetchLogs(forTripId: trip.id)
        } catch {
            print("Failed to fetch voice logs: \(error)")
        }
    }

    private func statusColor(for status: VoiceLogStatus) -> Color {
        switch status {
        case .enRoute:   return .green
        case .delayed:   return .orange
        case .arrived:   return .teal
        case .pickedUp:  return .blue
        case .breakdown: return .red
        case .other:     return .gray
        }
    }
}

struct OrderDetailInfoRow: View {
    let icon: String
    let title: String
    let value: String
    var valueColor: Color = Color.primary

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color(.tertiaryLabel))
                .frame(width: 24)

            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(Color.secondary)

            Spacer()

            Text(value)
                .font(.body)
                .foregroundStyle(valueColor)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - FactChip

struct FactChip: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(text)
                .font(.system(size: 12, weight: .bold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.1))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        OrderDetailView(
            trip: Trip(
                id: UUID(),
                vehicleId: UUID(),
                driverId: UUID(),
                routeId: UUID(),
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                distance: 42.5,
                status: .active,
                orderType: .bulkOrderShip
            ),
            viewModel: OrdersViewModel()
        )
    }
}
