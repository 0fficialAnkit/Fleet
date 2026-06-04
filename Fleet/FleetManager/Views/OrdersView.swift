import SwiftUI
internal import Auth

struct OrdersView: View {
    @State private var viewModel = OrdersViewModel()
    @State private var selectedFilter: TripStatus? = nil
    @State private var isAddingOrder = false
    @State private var navigationPath = [Trip]()
    @Environment(AuthViewModel.self) private var authViewModel

    var filteredTrips: [Trip] {
        let trips: [Trip]
        if let status = selectedFilter {
            trips = viewModel.trips.filter { $0.status == status }
        } else {
            trips = viewModel.trips
        }
        return trips.sorted { lhs, rhs in
            let lDate = lhs.createdAt ?? Date.distantPast
            let rDate = rhs.createdAt ?? Date.distantPast
            if lDate != rDate { return lDate > rDate }
            let lStart = lhs.startTime ?? Date.distantPast
            let rStart = rhs.startTime ?? Date.distantPast
            return lStart > rStart
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if viewModel.isLoading && viewModel.trips.isEmpty {
                    ProgressView()
                } else {
                    List {
                        // Filter pills
                        Section {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    FilterButton(title: "All", isSelected: selectedFilter == nil) {
                                        withAnimation(.easeInOut(duration: 0.2)) { selectedFilter = nil }
                                    }
                                    ForEach(TripStatus.allCases, id: \.self) { status in
                                        FilterButton(
                                            title: status == .scheduled ? "Upcoming" : status.rawValue.capitalized,
                                            isSelected: selectedFilter == status
                                        ) {
                                            withAnimation(.easeInOut(duration: 0.2)) { selectedFilter = status }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                            .padding(.vertical, 8)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)

                        // Orders list
                        if filteredTrips.isEmpty {
                            Section {
                                ContentUnavailableView(
                                    "No Orders",
                                    systemImage: "shippingbox",
                                    description: Text("No orders match this filter.")
                                )
                                .padding(.vertical, 20)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        } else {
                            Section {
                                ForEach(filteredTrips) { trip in
                                    Button {
                                        navigationPath.append(trip)
                                    } label: {
                                        OrderCardView(trip: trip, viewModel: viewModel)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                        }
                    }
                    .refreshable { await viewModel.loadData() }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Orders")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAddingOrder = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $isAddingOrder) {
                AddOrderView(viewModel: viewModel)
            }
            .navigationDestination(for: Trip.self) { trip in
                OrderDetailView(trip: trip, viewModel: viewModel)
            }
            .task { }
            .onChange(of: authViewModel.currentUser?.id, initial: true) { _, _ in
                guard let adminId = authViewModel.currentUserId else { return }
                viewModel.adminId = adminId
                Task {
                    await viewModel.loadData()
                    viewModel.setupRealtime()
                }
            }
        }
    }
}

// MARK: - Order Card

struct OrderCardView: View {
    let trip: Trip
    let viewModel: OrdersViewModel

    var route: Route?  { viewModel.route(for: trip.routeId) }
    var vehicle: Vehicle? { viewModel.vehicles.first { $0.id == trip.vehicleId } }
    var driver: Profile? {
        guard let id = trip.driverId else { return nil }
        return viewModel.profiles.first { $0.id == id }
    }

    var orderIcon: String {
        switch trip.orderType {
        case .bulkOrderShip: return "shippingbox.fill"
        case .pickUpAndDrop:  return "arrow.left.arrow.right"
        case .travel:         return "car.fill"
        case .none:           return "shippingbox"
        }
    }

    var orderColor: Color {
        switch trip.orderType {
        case .bulkOrderShip: return .orange
        case .pickUpAndDrop:  return .teal
        case .travel:         return .indigo
        case .none:           return .secondary
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
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Header: type icon + name + status
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(orderColor.opacity(0.12))
                        .frame(width: 32, height: 32)
                    Image(systemName: orderIcon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(orderColor)
                }
                Text(trip.orderType?.displayName ?? "Order")
                    .font(.headline)
                Spacer()
                StatusBadge(text: trip.status?.rawValue.capitalized ?? "Unknown",
                            color: viewModel.getStatusColor(for: trip.status))
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }

            // Route timeline
            if let start = route?.startLocation, let end = route?.endLocation {
                HStack(alignment: .top, spacing: 10) {
                    VStack(spacing: 3) {
                        Circle().fill(.green).frame(width: 7, height: 7)
                        Rectangle().fill(Color(.separator)).frame(width: 1.5, height: 16)
                        Circle().fill(.red).frame(width: 7, height: 7)
                    }
                    .padding(.top, 3)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(start)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text(end)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                    }
                }
                .padding(.leading, 2)
            } else if let name = route?.routeName {
                Label(name, systemImage: "map")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Driver + Vehicle
            HStack(spacing: 16) {
                Label {
                    Text(driver?.fullName ?? "Unassigned")
                        .font(.footnote)
                        .foregroundStyle(driver != nil ? .primary : .secondary)
                        .lineLimit(1)
                } icon: {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.teal)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Label {
                    Text(vehicle.map { "\($0.make ?? "") \($0.model ?? "")" } ?? "No Vehicle")
                        .font(.footnote)
                        .foregroundStyle(vehicle != nil ? .primary : .secondary)
                        .lineLimit(1)
                } icon: {
                    Image(systemName: vehicleIcon)
                        .foregroundStyle(.indigo)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            // Footer: date + order ID
            HStack {
                Label(formattedDate, systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("#\(trip.id.uuidString.prefix(8).uppercased())")
                    .font(.caption.monospaced())
                    .foregroundStyle(Color(.tertiaryLabel))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    OrdersView()
}
