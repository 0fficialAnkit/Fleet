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
                                        },
                                        onDropoffDone: { id, vId, fenceId in
                                            viewModel.gf_dropoffDone(tripId: id, vehicleId: vId, geofenceId: fenceId)
                                        }
                                    )) {
                                        TripListRow(
                                            trip: trip,
                                            route: viewModel.routeForTrip(trip),
                                            vehicle: viewModel.vehicleForTrip(trip)
                                        )
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
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
    let trip:    Trip
    let route:   Route?
    let vehicle: Vehicle?

    // MARK: - Computed

    var statusColor: Color {
        switch trip.status {
        case .scheduled: return .blue
        case .active:    return .green
        case .completed: return .green
        case .cancelled: return .red
        default:         return Color(.quaternaryLabel)
        }
    }

    var statusLabel: String {
        switch trip.status {
        case .scheduled: return "Scheduled"
        case .active:    return "Active"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        default:         return "Unknown"
        }
    }

    var orderIcon: String {
        switch trip.orderType {
        case .bulkOrderShip: return "shippingbox.fill"
        case .pickUpAndDrop:  return "arrow.left.arrow.right"
        case .travel:         return "car.fill"
        default:              return "shippingbox"
        }
    }

    var orderColor: Color {
        switch trip.orderType {
        case .bulkOrderShip: return .orange
        case .pickUpAndDrop:  return .teal
        case .travel:         return .indigo
        default:              return .secondary
        }
    }

    var vehicleIcon: String {
        guard let type = vehicle?.vehicleType else { return "car.fill" }
        switch type {
        case .twoWheeler:   return "scooter"
        case .threeWheeler: return "car.2.fill"
        case .car:          return "car.fill"
        case .truck:        return "box.truck.fill"
        }
    }

    var formattedDate: String {
        guard let date = trip.startTime else { return "Not Scheduled" }
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short
        return f.string(from: date)
    }

    // MARK: - Body  (matches OrderCardView style, driver-green theme)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // ── Header: icon + order type + status badge ──────────────────
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: orderIcon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(orderColor.gradient))

                    Text(trip.orderType?.displayName ?? "Trip")
                        .font(.headline.bold())
                        .foregroundStyle(.primary)
                }
                Spacer()
                StatusBadge(text: statusLabel, color: statusColor)
            }

            // ── Route timeline (green dot → line → red dot) ───────────────
            if let start = route?.startLocation, let end = route?.endLocation {
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 4) {
                        Circle().fill(Color.green).frame(width: 8, height: 8)
                        Rectangle().fill(Color(.separator)).frame(width: 2, height: 18)
                        Circle().fill(Color.red).frame(width: 8, height: 8)
                    }
                    .frame(width: 8)
                    .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(start)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text(end)
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 4)
            }

            Divider()

            // ── Vehicle info ──────────────────────────────────────────────
            HStack(spacing: 8) {
                Image(systemName: vehicleIcon)
                    .font(.system(size: 18))
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text("VEHICLE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color(.secondaryLabel))
                    Text(vehicle != nil
                         ? "\(vehicle?.make ?? "") \(vehicle?.model ?? "")"
                         : "No Vehicle")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(vehicle != nil ? .primary : .secondary)
                        .lineLimit(1)
                }
            }

            Divider()

            // ── Footer: date pill + order ID ──────────────────────────────
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Text(formattedDate)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))

                Spacer()

                Text("#\(trip.id.uuidString.prefix(8).uppercased())")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color(.tertiaryLabel))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color(.quaternarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

#Preview {
    DriverTripsView()
        .environment(AuthViewModel())
}
