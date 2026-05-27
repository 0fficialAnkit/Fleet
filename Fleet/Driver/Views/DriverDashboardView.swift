import SwiftUI
import Supabase

struct DriverDashboardView: View {

    @State private var viewModel = DriverDashboardViewModel()
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var selectedTrip: Trip?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                if viewModel.isLoading && viewModel.trips.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.green))
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            greetingHeader
                            activeTripBanner
                            statsRow
                            upcomingTripSection
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                    .refreshable { await viewModel.loadData() }
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    NavigationLink(destination: NotificationsView()) {
                        Image(systemName: "bell.badge")
                            .font(.title3)
                            .foregroundStyle(Color.green)
                    }

                    NavigationLink(destination: DriverProfileView()) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.green)
                    }
                }
            }
            .onChange(of: authViewModel.currentUser?.id, initial: true) { _, newUserId in
                guard let userId = newUserId else { return }
                viewModel.currentUserId = userId
                viewModel.driverName = authViewModel.currentProfile?.fullName ?? "Driver"
                Task {
                    viewModel.requestLocationPermission()
                    
                    await viewModel.loadData()
                    viewModel.setupRealtime()
                }
            }
            .onChange(of: authViewModel.currentProfile?.fullName) { _, newName in
                if let newName {
                    viewModel.driverName = newName
                }
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
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.secondary)

            Text(viewModel.driverName.components(separatedBy: " ").first ?? "Driver")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)

            Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(Color(UIColor.tertiaryLabel))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
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
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 10, height: 10)
                                .overlay(
                                    Circle()
                                        .stroke(Color.green.opacity(0.3), lineWidth: 3)
                                )

                            Text("Trip In Progress")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.green)
                        }

                        Spacer()

                        if let orderType = trip.orderType {
                            StatusBadge(text: orderType.displayName, color: Color.blue, icon: "shippingbox")
                        }
                    }

                    // Route info
                    HStack(spacing: 12) {
                        VStack(spacing: 4) {
                            Circle().fill(Color.green).frame(width: 8, height: 8)
                            Rectangle().fill(Color(UIColor.separator)).frame(width: 2, height: 20)
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.red)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(route?.startLocation ?? "Pickup Location")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.primary)
                                .lineLimit(1)
                            Text(route?.endLocation ?? "Drop-off Location")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.primary)
                                .lineLimit(1)
                        }

                        Spacer()
                    }

                    // Vehicle + time
                    HStack(spacing: 16) {
                        if let vehicle {
                            Label("\(vehicle.make ?? "") \(vehicle.model ?? "")", systemImage: "truck.box.fill")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundStyle(Color.secondary)
                        }

                        Spacer()

                        if let startTime = trip.startTime {
                            Label("Started \(startTime.formatted(date: .omitted, time: .shortened))", systemImage: "clock.fill")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundStyle(Color(UIColor.tertiaryLabel))
                        }
                    }
                }
                .padding(16)
                .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.green.opacity(0.4), lineWidth: 1.5)
                )
                .shadow(color: Color.green.opacity(0.15), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Stats Row
    private var statsRow: some View {
        HStack(spacing: 16) {
            // Achievements Card (60% width)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Achievements", systemImage: "trophy.fill")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.yellow)
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color.green)
                }

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(viewModel.totalCompletedTrips)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(Color.primary)
                        Text("Completed")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.secondary)
                    }

                    Rectangle()
                        .fill(Color(UIColor.separator))
                        .frame(width: 1, height: 36)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(format: "%.0f km", viewModel.totalDistanceKm))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(Color.primary)
                        Text("Distance")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)

            // Hours Active Card (40% width)
            VStack(alignment: .leading, spacing: 10) {
                Label("Active Time", systemImage: "clock.badge.checkmark.fill")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.green)

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.1f hrs", viewModel.totalHoursActive))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.primary)
                    Text("Hours Active")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.secondary)
                }
            }
            .padding(16)
            .frame(width: 130, alignment: .leading)
            .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
        }
    }

    // MARK: Upcoming Trip
    private var upcomingTripSection: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 36))
                        .foregroundStyle(Color(UIColor.tertiaryLabel))
                    Text("No upcoming trips scheduled")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
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
        case .scheduled: return Color.yellow
        case .active:    return Color.green
        case .completed: return Color.green
        case .cancelled: return Color.red
        case .none:      return Color(UIColor.quaternaryLabel)
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
        VStack(alignment: .leading, spacing: 8) {
            // Top: Route ID + status + order type
            HStack {
                Text("Route #\(trip.id.uuidString.prefix(6).uppercased())")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.primary)

                Spacer()

                if let orderType = trip.orderType {
                    StatusBadge(text: orderType.displayName, color: Color.blue, icon: orderTypeIcon(orderType))
                }

                StatusBadge(text: statusText, color: statusColor)
            }

            // Origin → Destination
            HStack(spacing: 10) {
                VStack(spacing: 3) {
                    Circle().fill(Color.green).frame(width: 7, height: 7)
                    Rectangle().fill(Color(UIColor.separator)).frame(width: 1.5, height: 16)
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.red)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(route?.startLocation ?? "Pickup")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)
                    Text(route?.endLocation ?? "Destination")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }

            // Bottom: Vehicle + time + distance
            HStack(spacing: 16) {
                if let vehicle {
                    Label("\(vehicle.make ?? "") \(vehicle.model ?? "")", systemImage: "truck.box.fill")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(Color(UIColor.tertiaryLabel))
                        .lineLimit(1)
                }

                Spacer()

                if let start = trip.startTime {
                    Label(start.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(Color(UIColor.tertiaryLabel))
                }

                if let distance = trip.distance, distance > 0 {
                    Label(String(format: "%.1f km", distance), systemImage: "road.lanes")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(Color(UIColor.tertiaryLabel))
                }
            }
        }
        .padding(16)
        .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(statusColor.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
    }

    private func orderTypeIcon(_ type: OrderType) -> String {
        switch type {
        case .pickUpAndDrop: return "shippingbox"
        case .bulkOrderShip: return "cube.box.fill"
        case .travel:        return "car.fill"
        }
    }
}



#Preview {
    NavigationStack {
        DriverDashboardView()
            .environment(AuthViewModel())
    }
}
