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
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.trips.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            
                            // Filters
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
                            
                            // Orders List
                            if filteredTrips.isEmpty {
                                Text("No orders found.")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(Color.secondary)
                                    .padding(.top, 40)
                            } else {
                                ForEach(filteredTrips) { trip in
                                    NavigationLink(value: trip) {
                                        OrderCardView(trip: trip, viewModel: viewModel)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.bottom, 40)
                    }
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
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
                
                Spacer()
                
                StatusBadge(text: trip.status?.rawValue.capitalized ?? "Unknown", color: viewModel.getStatusColor(for: trip.status))
            }
            
            // Route Name & Chevron
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.orderType?.displayName ?? route?.routeName ?? "Unknown Route")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.primary)
                    
                    if let dest = route?.endLocation {
                        Text(dest)
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(Color.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            .padding(.vertical, 2)
            
            Divider().background(Color(UIColor.separator))
            
            // Footer: Date & Order Type Badge
            HStack {
                Label(formattedDate, systemImage: "calendar")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
                
                Spacer()
                
                if let type = trip.orderType {
                    Text(type.displayName)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(Color.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .contentShape(Rectangle())
        .padding(16)
        .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
    }
}

#Preview {
    OrdersView()
}
