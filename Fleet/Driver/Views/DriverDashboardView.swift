import SwiftUI
import Supabase

struct DriverDashboardView: View {

    @State private var viewModel = DriverDashboardViewModel()
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var showingNotifications = false
    @State private var showingProfile = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.trips.isEmpty {
                    ProgressView()
                        .tint(Color.green)
                } else {
                    List {
                        Section { overviewCard }

                        todayScheduleSection
                    }
                    .refreshable { await viewModel.loadData() }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { showingNotifications = true } label: {
                        Image(systemName: "bell")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color.primary)
                    }
                    Button { showingProfile = true } label: {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(Color.green)
                    }
                }
            }
            .sheet(isPresented: $showingNotifications) {
                NotificationsView()
            }
            .sheet(isPresented: $showingProfile) {
                DriverProfileView()
                    .environment(authViewModel)
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
                if let newName { viewModel.driverName = newName }
            }
        }
    }

    // MARK: - Overview Card

    private var overviewCard: some View {
        let scheduledCount = viewModel.trips.filter { $0.status == .scheduled }.count
        let completedCount = viewModel.totalCompletedTrips
        let totalTrips     = viewModel.trips.count

        return VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.green.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: "truck.box.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Color.green)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("My Trips \(totalTrips)")
                        .font(.title2.bold())
                        .foregroundStyle(Color.primary)
                }

                Spacer()
            }

            Divider()
                .background(Color(.separator))
                .padding(.vertical, 16)

            HStack(spacing: 8) {
                FleetStatPill(
                    value: scheduledCount,
                    label: "Scheduled",
                    color: Color.blue
                )
                FleetStatPill(
                    value: completedCount,
                    label: "Completed",
                    color: Color.green
                )
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Today's Schedule Section

    private var todayScheduleSection: some View {
        let todayTrips = viewModel.todaysTrips

        return Section(header: HStack {
            Text("Today's Schedule")
            Spacer()
            if !todayTrips.isEmpty {
                Text("\(todayTrips.count) trip\(todayTrips.count == 1 ? "" : "s")")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Color.secondary)
                    .textCase(.none)
            }
        }) {
            if todayTrips.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("All caught up!")
                            .font(.body.bold())
                            .foregroundStyle(Color.primary)
                        Text("No trips scheduled for today")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                }
                .padding(.vertical, 6)
            } else {
                ForEach(todayTrips) { trip in
                    NavigationLink(destination: TripDetailView(
                        trip: trip,
                        onStart: { id, vId, notes, urls in
                            viewModel.startTrip(id: id, vehicleId: vId, notes: notes, imageUrls: urls)
                        },
                        onEnd: { id, vId, notes, urls in
                            viewModel.endTrip(id: id, vehicleId: vId, notes: notes, imageUrls: urls)
                        }
                    )) {
                        DriverTripRow(
                            trip: trip,
                            route: viewModel.routeForTrip(trip),
                            vehicle: viewModel.vehicleForTrip(trip)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Driver Trip Row

struct DriverTripRow: View {
    let trip: Trip
    let route: Route?
    let vehicle: Vehicle?

    var statusColor: Color {
        switch trip.status {
        case .scheduled: return Color.blue
        case .active:    return Color.green
        case .completed: return Color.green
        case .cancelled: return Color.red
        case .none:      return Color(.quaternaryLabel)
        }
    }

    var statusText: String {
        switch trip.status {
        case .scheduled: return "Scheduled"
        case .active:    return "Active"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .none:      return "Unknown"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(trip.orderType?.displayName ?? "Trip")
                    .font(.body.bold())
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                Spacer()
                StatusBadge(text: statusText, color: statusColor)
            }

            if let start = route?.startLocation, let end = route?.endLocation {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.forward")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.secondary)
                    Text("\(LocationParser.decode(start).address) → \(LocationParser.decode(end).address)")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                }
            }

            HStack {
                if let vehicle {
                    HStack(spacing: 6) {
                        Image(systemName: "truck.box.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.green)
                        Text("\(vehicle.make ?? "") \(vehicle.model ?? "")")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                    }
                }
                Spacer()
                if let start = trip.startTime {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(.tertiaryLabel))
                        Text(start.formatted(date: .omitted, time: .shortened))
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    DriverDashboardView()
        .environment(AuthViewModel())
}
