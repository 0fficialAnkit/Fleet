import SwiftUI
import Supabase

struct DriverDashboardView: View {

    @State private var viewModel = DriverDashboardViewModel()
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var selectedTrip: Trip?

    var body: some View {
        NavigationStack {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()

                if viewModel.isLoading && viewModel.trips.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: themeModel.driverPrimary))
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: themeModel.spacingLG) {
                            greetingHeader
                            activeTripBanner
                            statsRow
                            upcomingTripSection
                            quickActionsSection
                        }
                        .padding(.horizontal, themeModel.spacingMD)
                        .padding(.top, themeModel.spacingSM)
                        .padding(.bottom, themeModel.spacingXXL)
                    }
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    NavigationLink(destination: NotificationsView()) {
                        Image(systemName: "bell.badge")
                            .font(.title3)
                            .foregroundStyle(themeModel.driverPrimary)
                    }

                    NavigationLink(destination: DriverProfileView()) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundStyle(themeModel.driverPrimary)
                    }
                }
            }
            .task {
                viewModel.currentUserId = authViewModel.currentUser?.id
                viewModel.driverName = authViewModel.currentProfile?.fullName ?? "Driver"
                await viewModel.loadData()
                viewModel.setupRealtime()
            }
        }
    }
}

// MARK: - Subviews

extension DriverDashboardView {

    // MARK: Greeting Header
    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(viewModel.greetingText()),")
                .font(themeModel.headline())
                .foregroundStyle(themeModel.textSecondary)

            Text(viewModel.driverName.components(separatedBy: " ").first ?? "Driver")
                .font(themeModel.largeTitle(30))
                .foregroundStyle(themeModel.textPrimary)

            Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(themeModel.caption())
                .foregroundStyle(themeModel.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, themeModel.spacingSM)
    }

    // MARK: Active Trip Banner
    @ViewBuilder
    private var activeTripBanner: some View {
        if let trip = viewModel.activeTrip {
            let route = viewModel.routeForTrip(trip)
            let vehicle = viewModel.vehicleForTrip(trip)

            NavigationLink(destination: TripDetailView(
                trip: trip,
                onStart: { id, vId, notes, urls in viewModel.startTrip(id: id, vehicleId: vId, notes: notes, imageUrls: urls) },
                onEnd:   { id, vId, notes, urls in viewModel.endTrip(id: id, vehicleId: vId, notes: notes, imageUrls: urls) }
            )) {
                VStack(alignment: .leading, spacing: themeModel.spacingMD) {
                    HStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(themeModel.driverPrimary)
                                .frame(width: 10, height: 10)
                                .overlay(
                                    Circle()
                                        .stroke(themeModel.driverPrimary.opacity(0.3), lineWidth: 3)
                                )

                            Text("Trip In Progress")
                                .font(themeModel.bodyMedium())
                                .foregroundStyle(themeModel.driverPrimary)
                        }

                        Spacer()

                        if let orderType = trip.orderType {
                            StatusBadge(text: orderType.displayName, color: themeModel.info, icon: "shippingbox")
                        }
                    }

                    // Route info
                    HStack(spacing: 12) {
                        VStack(spacing: 4) {
                            Circle().fill(themeModel.success).frame(width: 8, height: 8)
                            Rectangle().fill(themeModel.divider).frame(width: 2, height: 20)
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(themeModel.danger)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(route?.startLocation ?? "Pickup Location")
                                .font(themeModel.bodyMedium())
                                .foregroundStyle(themeModel.textPrimary)
                                .lineLimit(1)
                            Text(route?.endLocation ?? "Drop-off Location")
                                .font(themeModel.bodyMedium())
                                .foregroundStyle(themeModel.textPrimary)
                                .lineLimit(1)
                        }

                        Spacer()
                    }

                    // Vehicle + time
                    HStack(spacing: themeModel.spacingMD) {
                        if let vehicle {
                            Label("\(vehicle.make ?? "") \(vehicle.model ?? "")", systemImage: "truck.box.fill")
                                .font(themeModel.caption())
                                .foregroundStyle(themeModel.textSecondary)
                        }

                        Spacer()

                        if let startTime = trip.startTime {
                            Label("Started \(startTime.formatted(date: .omitted, time: .shortened))", systemImage: "clock.fill")
                                .font(themeModel.caption())
                                .foregroundStyle(themeModel.textTertiary)
                        }
                    }
                }
                .padding(themeModel.spacingMD)
                .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                        .stroke(themeModel.driverPrimary.opacity(0.4), lineWidth: 1.5)
                )
                .shadow(color: themeModel.driverPrimary.opacity(0.15), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Stats Row
    private var statsRow: some View {
        HStack(spacing: themeModel.spacingMD) {
            // Achievements Card (60% width)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Achievements", systemImage: "trophy.fill")
                        .font(themeModel.bodyMedium())
                        .foregroundStyle(Color.yellow)
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(themeModel.success)
                }

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(viewModel.totalCompletedTrips)")
                            .font(themeModel.title(22))
                            .fontWeight(.bold)
                            .foregroundStyle(themeModel.textPrimary)
                        Text("Completed")
                            .font(themeModel.caption())
                            .foregroundStyle(themeModel.textSecondary)
                    }

                    Rectangle()
                        .fill(themeModel.divider)
                        .frame(width: 1, height: 36)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(format: "%.0f km", viewModel.totalDistanceKm))
                            .font(themeModel.title(22))
                            .fontWeight(.bold)
                            .foregroundStyle(themeModel.textPrimary)
                        Text("Distance")
                            .font(themeModel.caption())
                            .foregroundStyle(themeModel.textSecondary)
                    }
                }
            }
            .padding(themeModel.spacingMD)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            )
            .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)

            // Hours Active Card (40% width)
            VStack(alignment: .leading, spacing: 10) {
                Label("Active Time", systemImage: "clock.badge.checkmark.fill")
                    .font(themeModel.bodyMedium())
                    .foregroundStyle(themeModel.driverPrimary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.1f hrs", viewModel.totalHoursActive))
                        .font(themeModel.title(22))
                        .fontWeight(.bold)
                        .foregroundStyle(themeModel.textPrimary)
                    Text("Hours Active")
                        .font(themeModel.caption())
                        .foregroundStyle(themeModel.textSecondary)
                }
            }
            .padding(themeModel.spacingMD)
            .frame(width: 130, alignment: .leading)
            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            )
            .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
        }
    }

    // MARK: Upcoming Trip
    private var upcomingTripSection: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
            SectionHeader(title: "Upcoming Assignment")

            if let trip = viewModel.upcomingTrip {
                NavigationLink(destination: TripDetailView(
                    trip: trip,
                    onStart: { id, vId, notes, urls in viewModel.startTrip(id: id, vehicleId: vId, notes: notes, imageUrls: urls) },
                    onEnd:   { id, vId, notes, urls in viewModel.endTrip(id: id, vehicleId: vId, notes: notes, imageUrls: urls) }
                )) {
                    EnrichedTripCard(
                        trip: trip,
                        route: viewModel.routeForTrip(trip),
                        vehicle: viewModel.vehicleForTrip(trip)
                    )
                }
                .buttonStyle(.plain)
            } else {
                VStack(spacing: themeModel.spacingSM) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 36))
                        .foregroundStyle(themeModel.textTertiary)
                    Text("No upcoming trips scheduled")
                        .font(themeModel.body())
                        .foregroundStyle(themeModel.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, themeModel.spacingLG)
                .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                )
            }
        }
    }

    // MARK: Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
            SectionHeader(title: "Vehicle Services")

            if let vehicle = viewModel.assignedVehicle {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: themeModel.spacingMD) {
                    NavigationLink(destination: DriverVehicleDetailView(vehicle: vehicle)) {
                        QuickActionCard(
                            icon: "info.circle.fill",
                            title: "Vehicle Info",
                            subtitle: "\(vehicle.make ?? "My") \(vehicle.model ?? "Vehicle")",
                            color: themeModel.driverPrimary
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink(destination: DriverReportIssueView(vehicle: vehicle)) {
                        QuickActionCard(
                            icon: "exclamationmark.triangle.fill",
                            title: "Report Issue",
                            subtitle: "Log damage / defect",
                            color: themeModel.danger
                        )
                    }
                    .buttonStyle(.plain)
                }
            } else {
                HStack(spacing: themeModel.spacingMD) {
                    Image(systemName: "car.badge.gearshape")
                        .font(.title2)
                        .foregroundStyle(themeModel.textTertiary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No Assigned Vehicle")
                            .font(themeModel.bodyMedium())
                            .foregroundStyle(themeModel.textPrimary)
                        Text("Contact fleet manager for vehicle details")
                            .font(themeModel.caption())
                            .foregroundStyle(themeModel.textSecondary)
                    }
                    Spacer()
                }
                .padding(themeModel.spacingMD)
                .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                )
            }
        }
    }
}

// MARK: - Enriched Trip Card

struct EnrichedTripCard: View {
    let trip: Trip
    let route: Route?
    let vehicle: Vehicle?

    var statusColor: Color {
        switch trip.status {
        case .scheduled: return themeModel.warning
        case .active:    return themeModel.driverPrimary
        case .completed: return themeModel.success
        case .cancelled: return themeModel.danger
        case .none:      return themeModel.textDisabled
        }
    }

    var statusText: String {
        switch trip.status {
        case .scheduled: return "Scheduled"
        case .active:    return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .none:      return "Unknown"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingSM) {
            // Top: Route ID + status + order type
            HStack {
                Text("Route #\(trip.id.uuidString.prefix(6).uppercased())")
                    .font(themeModel.headline())
                    .foregroundStyle(themeModel.textPrimary)

                Spacer()

                if let orderType = trip.orderType {
                    StatusBadge(text: orderType.displayName, color: themeModel.info, icon: orderTypeIcon(orderType))
                }

                StatusBadge(text: statusText, color: statusColor)
            }

            // Origin → Destination
            HStack(spacing: 10) {
                VStack(spacing: 3) {
                    Circle().fill(themeModel.success).frame(width: 7, height: 7)
                    Rectangle().fill(themeModel.divider).frame(width: 1.5, height: 16)
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(themeModel.danger)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(route?.startLocation ?? "Pickup")
                        .font(themeModel.bodyMedium(14))
                        .foregroundStyle(themeModel.textPrimary)
                        .lineLimit(1)
                    Text(route?.endLocation ?? "Destination")
                        .font(themeModel.bodyMedium(14))
                        .foregroundStyle(themeModel.textSecondary)
                        .lineLimit(1)
                }

                Spacer()
            }

            // Bottom: Vehicle + time + distance
            HStack(spacing: themeModel.spacingMD) {
                if let vehicle {
                    Label("\(vehicle.make ?? "") \(vehicle.model ?? "")", systemImage: "truck.box.fill")
                        .font(themeModel.caption())
                        .foregroundStyle(themeModel.textTertiary)
                        .lineLimit(1)
                }

                Spacer()

                if let start = trip.startTime {
                    Label(start.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                        .font(themeModel.caption())
                        .foregroundStyle(themeModel.textTertiary)
                }

                if let distance = trip.distance, distance > 0 {
                    Label(String(format: "%.1f km", distance), systemImage: "road.lanes")
                        .font(themeModel.caption())
                        .foregroundStyle(themeModel.textTertiary)
                }
            }
        }
        .padding(themeModel.spacingMD)
        .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                .stroke(statusColor.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
    }

    private func orderTypeIcon(_ type: OrderType) -> String {
        switch type {
        case .pickUpAndDrop: return "shippingbox"
        case .bulkOrderShip: return "cube.box.fill"
        case .travel:        return "car.fill"
        }
    }
}

// MARK: - Quick Action Card

private struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingSM) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusXS, style: .continuous))

            Text(title)
                .font(themeModel.bodyMedium())
                .foregroundStyle(themeModel.textPrimary)

            Text(subtitle)
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
}

#Preview {
    NavigationStack {
        DriverDashboardView()
            .environment(AuthViewModel())
    }
}
