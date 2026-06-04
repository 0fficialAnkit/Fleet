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
                        Section { carbonScoreCard }
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
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)

                    Button { showingProfile = true } label: {
                        Image(systemName: "person.crop.circle")
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
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

    // MARK: - Carbon Score Card
    
    private var carbonScoreCard: some View {
        let driverTrips = viewModel.trips.filter { $0.driverId == viewModel.currentUserId }
        let vehiclesList = Array(viewModel.vehicles.values)
        let score = ESGService.calculateDriverCarbonScore(driverId: viewModel.currentUserId ?? UUID(), trips: viewModel.trips, vehicles: vehiclesList)
        
        let totalDistance = driverTrips.reduce(0.0) { $0 + ($1.distance ?? 0.0) }
        let totalEmissions = driverTrips.reduce(0.0) { sum, trip in
            if let vehicle = viewModel.vehicles[trip.vehicleId] {
                return sum + ESGService.calculateEmissions(for: trip, vehicle: vehicle)
            }
            return sum
        }
        
        return NavigationLink(destination: DriverCarbonDashboardView(carbonScore: score, totalEmissions: totalEmissions, totalDistance: totalDistance)) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
                        .frame(width: 46, height: 46)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(score) / 100.0)
                        .stroke(score >= 80 ? Color.green : (score >= 50 ? Color.orange : Color.red), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 46, height: 46)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(score)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(score >= 80 ? Color.green : (score >= 50 ? Color.orange : Color.red))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Carbon Score")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Tap to view your eco-profile")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 4)
        }
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
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(trip.orderType?.displayName ?? "Trip")
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                StatusBadge(text: statusText, color: statusColor)
            }

            if let start = route?.startLocation, let end = route?.endLocation {
                HStack(spacing: 8) {
                    VStack(spacing: 3) {
                        Circle().fill(.green).frame(width: 6, height: 6)
                        Rectangle().fill(Color(.separator)).frame(width: 1.5, height: 12)
                        Circle().fill(.red).frame(width: 6, height: 6)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(start).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                        Text(end).font(.subheadline).foregroundStyle(.primary).lineLimit(1)
                    }
                }
            }

            HStack {
                if let vehicle {
                    Label("\(vehicle.make ?? "") \(vehicle.model ?? "")", systemImage: "car")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let start = trip.startTime {
                    Label(start.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DriverDashboardView()
        .environment(AuthViewModel())
}
