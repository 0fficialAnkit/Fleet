import SwiftUI

struct OrdersView: View {
    @State private var viewModel = OrdersViewModel()
    @State private var selectedFilter: TripStatus? = nil
    @State private var selectedOrderType: OrderType? = nil
    @State private var navigationPath = [Trip]()

    var filteredTrips: [Trip] {
        if let status = selectedFilter {
            return viewModel.trips.filter { $0.status == status }
        }
        return viewModel.trips
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

                        Section {
                            if filteredTrips.isEmpty {
                                Text("No orders found.")
                                    .font(.body)
                                    .foregroundColor(Color.secondary)
                                    .padding(.vertical, 40)
                            } else {
                                ForEach(filteredTrips) { trip in
                                    NavigationLink(value: trip) {
                                        OrderCardView(trip: trip, viewModel: viewModel)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Orders")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(OrderType.allCases, id: \.self) { type in
                            Button(action: {
                                selectedOrderType = type
                            }) {
                                Text(type.displayName)
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color.primary)
                    }
                }
            }
            .sheet(item: $selectedOrderType) { orderType in
                VehicleSelectionView(orderType: orderType, viewModel: viewModel, selectedOrderType: $selectedOrderType)
            }
            .onChange(of: selectedOrderType) { _, newValue in
                if newValue == nil {
                    selectedFilter = nil
                }
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

    var formattedDate: String {
        guard let date = trip.startTime else { return "Not Scheduled" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Order ID & Status
            HStack {
                Text("ORDER #\(trip.id.uuidString.prefix(8).uppercased())")
                    .font(.caption)
                    .foregroundColor(Color(.tertiaryLabel))

                Spacer()

                StatusBadge(text: trip.status?.rawValue.capitalized ?? "Unknown", color: viewModel.getStatusColor(for: trip.status))
            }

            // Route Name & Chevron
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.orderType?.displayName ?? route?.routeName ?? "Unknown Route")
                        .font(.body.bold())
                        .foregroundColor(Color.primary)

                    if let dest = route?.endLocation {
                        Text(dest)
                            .font(.footnote)
                            .foregroundColor(Color.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
            .padding(.vertical, 2)

            Divider().background(Color(.separator))

            // Footer: Date & Order Type Badge
            HStack {
                Label(formattedDate, systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(Color(.tertiaryLabel))

                Spacer()

                if let type = trip.orderType {
                    Text(type.displayName)
                        .font(.caption.weight(.medium))
                        .foregroundColor(Color.teal)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.teal.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)

    }
}

#Preview {
    OrdersView()
}