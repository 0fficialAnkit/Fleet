import SwiftUI

struct OrdersView: View {
    @State private var viewModel = OrdersViewModel()
    @State private var selectedFilter: TripStatus? = nil
    @State private var isAddingOrder = false
    @State private var navigationPath = [Trip]()

    var filteredTrips: [Trip] {
        let trips: [Trip]
        if let status = selectedFilter {
            trips = viewModel.trips.filter { $0.status == status }
        } else {
            trips = viewModel.trips
        }
        return trips.sorted { lhs, rhs in
            switch (lhs.startTime, rhs.startTime) {
            case let (lDate?, rDate?):
                return lDate < rDate
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                return (lhs.createdAt ?? Date.distantPast) < (rhs.createdAt ?? Date.distantPast)
            }
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if viewModel.isLoading && viewModel.trips.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    List {
                        Section {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    FilterButton(title: "All", isSelected: selectedFilter == nil) {
                                        selectedFilter = nil
                                    }
                                    ForEach(TripStatus.allCases, id: \.self) { status in
                                        FilterButton(
                                            title: status.rawValue.capitalized,
                                            isSelected: selectedFilter == status
                                        ) {
                                            selectedFilter = status
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

                        if filteredTrips.isEmpty {
                            Section {
                                Text("No orders found.")
                                    .font(.body)
                                    .foregroundColor(Color.secondary)
                                    .padding(.vertical, 40)
                                    .frame(maxWidth: .infinity, alignment: .center)
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
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                    .refreshable { await viewModel.loadData() }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Orders")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAddingOrder = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color.primary)
                    }
                }
            }
            .sheet(isPresented: $isAddingOrder) {
                AddOrderView(viewModel: viewModel)
            }
            .navigationDestination(for: Trip.self) { trip in
                OrderDetailView(trip: trip, viewModel: viewModel)
            }
            .task {
                await viewModel.loadData()
                viewModel.setupRealtime()
            }
        }
    }
}

struct OrderCardView: View {
    let trip: Trip
    let viewModel: OrdersViewModel

    var route: Route? {
        viewModel.route(for: trip.routeId)
    }

    var vehicle: Vehicle? {
        viewModel.vehicles.first { $0.id == trip.vehicleId }
    }

    var driver: Profile? {
        guard let driverId = trip.driverId else { return nil }
        return viewModel.profiles.first { $0.id == driverId }
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
        case .bulkOrderShip: return Color.orange
        case .pickUpAndDrop: return Color.teal
        case .travel: return Color.indigo
        case .none: return Color.secondary
        }
    }

    var vehicleIcon: String {
        guard let type = vehicle?.vehicleType else { return "car.fill" }
        switch type {
        case .twoWheeler: return "scooter"
        case .threeWheeler: return "car.2.fill"
        case .car: return "car.fill"
        case .truck: return "box.truck.fill"
        }
    }

    var formattedDate: String {
        guard let date = trip.startTime else { return "Not Scheduled" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header: Type & Status
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: orderIcon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(orderColor.gradient)
                        )
                    
                    Text(trip.orderType?.displayName ?? "Custom Order")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.primary)
                }

                Spacer()

                StatusBadge(text: trip.status?.rawValue.capitalized ?? "Unknown", color: viewModel.getStatusColor(for: trip.status))
            }

            // Route representation (Timeline/connector style)
            if let start = route?.startLocation, let end = route?.endLocation {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 12) {
                        // Vertical timeline line & dots
                        VStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            
                            // Dotted/dashed connector line
                            Rectangle()
                                .fill(Color(.separator))
                                .frame(width: 2, height: 18)
                            
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                        }
                        .frame(width: 8)
                        .padding(.top, 4)

                        // Locations
                        VStack(alignment: .leading, spacing: 10) {
                            Text(start)
                                .font(.subheadline)
                                .foregroundColor(Color.secondary)
                                .lineLimit(1)
                            
                            Text(end)
                                .font(.subheadline.bold())
                                .foregroundColor(Color.primary)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.horizontal, 4)
            } else if let routeName = route?.routeName {
                // Fallback route name
                HStack(spacing: 8) {
                    Image(systemName: "map.fill")
                        .foregroundColor(.teal)
                        .font(.subheadline)
                    Text(routeName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                }
            }

            Divider()
                .background(Color(.separator).opacity(0.6))

            // Driver & Vehicle details side-by-side
            HStack(spacing: 16) {
                // Driver
                HStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color.teal)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DRIVER")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(.secondaryLabel))
                        Text(driver?.fullName ?? "Unassigned")
                            .font(.footnote.weight(.medium))
                            .foregroundColor(driver != nil ? Color.primary : Color.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Vehicle
                HStack(spacing: 8) {
                    Image(systemName: vehicleIcon)
                        .font(.system(size: 18))
                        .foregroundColor(Color.indigo)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("VEHICLE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(.secondaryLabel))
                        Text(vehicle != nil ? "\(vehicle?.make ?? "") \(vehicle?.model ?? "")" : "No Vehicle")
                            .font(.footnote.weight(.medium))
                            .foregroundColor(vehicle != nil ? Color.primary : Color.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()
                .background(Color(.separator).opacity(0.6))

            // Footer: Date & Order ID
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundColor(Color.teal)
                    Text(formattedDate)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color.teal)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.teal.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))

                Spacer()

                Text("#\(trip.id.uuidString.prefix(8).uppercased())")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(Color(.tertiaryLabel))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.quaternarySystemFill))
                    .cornerRadius(4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator).opacity(0.4), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    OrdersView()
}