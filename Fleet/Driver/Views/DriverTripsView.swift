import SwiftUI
import Supabase

struct DriverTripsView: View {

    @State private var viewModel = DriverTripsViewModel()
    @State private var selectedFilter: TripFilter = .remaining
    @State private var showingSchedule = false
    @Environment(AuthViewModel.self) private var authViewModel

    enum TripFilter: String, CaseIterable {
        case all       = "All"
        case remaining = "Upcoming"
        case completed = "Completed"
    }

    var filteredTrips: [Trip] {
        switch selectedFilter {
        case .all:       return viewModel.sortedTrips
        case .remaining: return viewModel.sortedTrips.filter { $0.status == .scheduled || $0.status == .active }
        case .completed: return viewModel.sortedTrips.filter { $0.status == .completed }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.trips.isEmpty {
                    ProgressView()
                        .tint(.green)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        // Filter chips
                        Section {
                            filterChips
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                        .listSectionSeparator(.hidden)

                        // Trip rows
                        Section {
                            if filteredTrips.isEmpty {
                                emptyState
                            } else {
                                ForEach(filteredTrips) { trip in
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
                                        }
                                    )) {
                                        TripListRow(
                                            trip: trip,
                                            route: viewModel.routeForTrip(trip),
                                            vehicle: viewModel.vehicleForTrip(trip)
                                        )
                                    }
                                }
                            }
                        }
                        .listSectionSeparator(.hidden)
                    }
                    .listStyle(.insetGrouped)
                    .refreshable { await viewModel.loadData() }
                }
            }
            .navigationTitle("Assigned Routes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingSchedule = true } label: {
                        Image(systemName: "calendar")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color.green)
                    }
                }
            }
            .sheet(isPresented: $showingSchedule) {
                DriverScheduleView(viewModel: viewModel)
            }
            .onChange(of: authViewModel.currentUser?.id, initial: true) { _, newUserId in
                guard let userId = newUserId else { return }
                viewModel.currentUserId = userId
                Task {
                    await viewModel.loadData()
                    viewModel.setupRealtime()
                }
            }
        }
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TripFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedFilter == filter ? Color.green : Color(.tertiarySystemFill))
                            .foregroundStyle(selectedFilter == filter ? .white : Color.primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "road.lanes")
                .font(.system(size: 36))
                .foregroundStyle(Color(.tertiaryLabel))
            Text("No trips found")
                .font(.body)
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .listRowBackground(Color.clear)
    }
}

// MARK: - Trip List Row

struct TripListRow: View {
    let trip: Trip
    let route: Route?
    let vehicle: Vehicle?

    var statusColor: Color {
        switch trip.status {
        case .scheduled: return .blue
        case .active:    return .green
        case .completed: return .green
        case .cancelled: return .red
        case .none:      return Color(.quaternaryLabel)
        }
    }

    var statusLabel: String {
        switch trip.status {
        case .scheduled: return "Scheduled"
        case .active:    return "Active"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .none:      return "Unknown"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // Top row: order type + status badge
            HStack {
                Text(trip.orderType?.displayName ?? "Trip")
                    .font(.body.bold())
                    .foregroundStyle(Color.primary)
                Spacer()
                StatusBadge(text: statusLabel, color: statusColor)
            }

            // Route: pickup → dropoff
            if let start = route?.startLocation, let end = route?.endLocation {
                HStack(spacing: 8) {
                    VStack(spacing: 3) {
                        Circle().fill(Color.green).frame(width: 7, height: 7)
                        Rectangle().fill(Color(.separator)).frame(width: 1.5, height: 14)
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.red)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text(start)
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                            .lineLimit(1)
                        Text(end)
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                            .lineLimit(1)
                    }
                }
            }

            // Bottom row: vehicle + date + distance
            HStack {
                if let vehicle {
                    HStack(spacing: 5) {
                        Image(systemName: "truck.box.fill")
                            .font(.caption)
                            .foregroundStyle(Color.green)
                        Text("\(vehicle.make ?? "") \(vehicle.model ?? "")")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                if let date = trip.startTime {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(Color(.tertiaryLabel))
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DriverTripsView()
        .environment(AuthViewModel())
}
