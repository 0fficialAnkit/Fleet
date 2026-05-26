import SwiftUI

struct OrderDetailView: View {
    let trip: Trip
    let viewModel: OrdersViewModel
    @Environment(\.dismiss) private var dismiss

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
                                .foregroundColor(orderColor)
                        }
                        .padding(.bottom, 8)

                        Text(route?.routeName ?? "Unknown Route")
                            .font(.title3.bold())
                            .foregroundColor(Color.primary)
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
//                    .cornerRadius(20)
//                    .padding(.horizontal, 16)
                    .padding(16)
                    .background(
                        Color(.tertiarySystemBackground).opacity(0.35)
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 20,
                            style: .continuous
                        )
                    )
                    .glassEffect(
                        in: RoundedRectangle(
                            cornerRadius: 20,
                            style: .continuous
                        )
                    )
                    .overlay(
                        RoundedRectangle(
                            cornerRadius: 20,
                            style: .continuous
                        )
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    )

                    .padding(.horizontal, 16)
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
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.primary)
                        .padding(8)
                }
            }
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
                .foregroundColor(Color(.tertiaryLabel))
                .frame(width: 24)

            Text(title)
                .font(.body.weight(.medium))
                .foregroundColor(Color.secondary)

            Spacer()

            Text(value)
                .font(.body)
                .foregroundColor(valueColor)
        }
        .padding(.vertical, 8)
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