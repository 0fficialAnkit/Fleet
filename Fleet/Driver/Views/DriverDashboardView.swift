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
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { showingNotifications = true } label: {
                        Image(systemName: "bell")
                    }
                    .tint(.primary)

                    Button { showingProfile = true } label: {
                        Image(systemName: "person.crop.circle")
                    }
                    .tint(.primary)
                }
            }
            .sheet(isPresented: $showingNotifications) { NotificationsView() }
            .sheet(isPresented: $showingProfile) {
                DriverProfileView().environment(authViewModel)
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
        let scheduled  = viewModel.trips.filter { $0.status == .scheduled }.count
        let completed  = viewModel.totalCompletedTrips
        let totalTrips = viewModel.trips.count

        return VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.green.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "truck.box")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.green)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("My Trips")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(totalTrips) total")
                        .font(.headline)
                }

                Spacer()
                
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    viewModel.toggleDutyStatus()
                }) {
                    Text(viewModel.isOnDuty ? "On Duty" : "Off Duty")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(viewModel.isOnDuty ? Color.green : Color.gray)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Divider().padding(.vertical, 14)

            HStack(spacing: 0) {
                kpiCell(value: "\(scheduled)", label: "Scheduled", color: .blue)
                Divider().frame(height: 36)
                kpiCell(value: "\(completed)", label: "Completed", color: .green)
                if let active = viewModel.activeTrip {
                    Divider().frame(height: 36)
                    kpiCell(value: "1", label: "Active", color: .green)
                    let _ = active
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func kpiCell(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }


    // MARK: - Today's Schedule

    private var todayScheduleSection: some View {
        let todayTrips = viewModel.todaysTrips
        return Section {
            if todayTrips.isEmpty {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("All caught up!")
                            .font(.subheadline.weight(.medium))
                        Text("No trips scheduled for today")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "calendar.badge.checkmark")
                        .foregroundStyle(.green)
                        .font(.title3)
                }
                .padding(.vertical, 6)
            } else {
                ForEach(todayTrips) { trip in
                    NavigationLink(destination: TripDetailView(
                        trip: trip,
                        onStart: { id, vId, notes, urls in
                            viewModel.startTrip(id: id, vehicleId: vId, notes: notes, imageUrls: urls)
                        },
                        onEnd: { id, vId, distance, notes, urls in
                            viewModel.endTrip(id: id, vehicleId: vId, distance: distance, notes: notes, imageUrls: urls)
                        },
                        onPickupDone: { id, vId in
                            viewModel.gf_pickupDone(tripId: id, vehicleId: vId)
                        },
                        onDropoffDone: { id, vId, fenceId in
                            viewModel.gf_dropoffDone(tripId: id, vehicleId: vId, geofenceId: fenceId)
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
        } header: {
            HStack {
                Text("Today's Schedule")
                Spacer()
                if !todayTrips.isEmpty {
                    Text("\(todayTrips.count) trip\(todayTrips.count == 1 ? "" : "s")")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .textCase(.none)
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
        case .scheduled: return .blue
        case .active:    return .green
        case .completed: return .green
        case .cancelled: return .red
        default:         return Color(.quaternaryLabel)
        }
    }

    var statusText: String {
        switch trip.status {
        case .scheduled: return "Scheduled"
        case .active:    return "Active"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        default:         return "Unknown"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: "map.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.blue)
                    }
                    Text(trip.orderType?.displayName ?? "Trip")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                Spacer()
                StatusBadge(text: statusText, color: statusColor)
            }

            Divider()

            // Route
            if let start = route?.startLocation, let end = route?.endLocation {
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 4) {
                        Image(systemName: "circle.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.green)
                            .background(Circle().fill(.white))
                        
                        Rectangle()
                            .fill(Color(.tertiaryLabel))
                            .frame(width: 1.5, height: 20)
                        
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.red)
                            .background(Circle().fill(.white))
                    }
                    .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("PICKUP")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.secondary)
                            Text(start)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("DROPOFF")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.secondary)
                            Text(end)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }

            // Footer
            HStack(spacing: 12) {
                if let vehicle {
                    HStack(spacing: 6) {
                        Image(systemName: "car.fill")
                            .foregroundStyle(.teal)
                        Text("\(vehicle.make ?? "") \(vehicle.model ?? "")")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.teal.opacity(0.12))
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                if let start = trip.startTime {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(.orange)
                        Text(start.formatted(date: .omitted, time: .shortened))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    DriverDashboardView()
        .environment(AuthViewModel())
}
