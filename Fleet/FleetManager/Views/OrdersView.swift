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
                themeModel.backgroundPrimary.ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.trips.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: themeModel.spacingMD) {
                            
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
                                .padding(.horizontal, themeModel.spacingMD)
                            }
                            .padding(.vertical, themeModel.spacingSM)
                            
                            // Orders List
                            if filteredTrips.isEmpty {
                                Text("No orders found.")
                                    .font(themeModel.body(16))
                                    .foregroundColor(themeModel.textSecondary)
                                    .padding(.top, 40)
                            } else {
                                ForEach(filteredTrips) { trip in
                                    NavigationLink(value: trip) {
                                        OrderCardView(trip: trip, viewModel: viewModel)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, themeModel.spacingMD)
                            }
                        }
                        .padding(.bottom, themeModel.spacingXXL)
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
                            .foregroundStyle(themeModel.textPrimary)
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
        VStack(alignment: .leading, spacing: themeModel.spacingSM) {
            // Header: Order ID & Status
            HStack {
                Text("ORDER #\(trip.id.uuidString.prefix(8).uppercased())")
                    .font(themeModel.caption(12))
                    .foregroundColor(themeModel.textTertiary)
                
                Spacer()
                
                StatusBadge(text: trip.status?.rawValue.capitalized ?? "Unknown", color: viewModel.getStatusColor(for: trip.status))
            }
            
            // Route Name & Chevron
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.orderType?.displayName ?? route?.routeName ?? "Unknown Route")
                        .font(themeModel.headline(16))
                        .foregroundColor(themeModel.textPrimary)
                    
                    if let dest = route?.endLocation {
                        Text(dest)
                            .font(themeModel.caption(13))
                            .foregroundColor(themeModel.textSecondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeModel.textTertiary)
            }
            .padding(.vertical, 2)
            
            Divider().background(themeModel.divider)
            
            // Footer: Date & Order Type Badge
            HStack {
                Label(formattedDate, systemImage: "calendar")
                    .font(themeModel.caption(12))
                    .foregroundColor(themeModel.textTertiary)
                
                Spacer()
                
                if let type = trip.orderType {
                    Text(type.displayName)
                        .font(themeModel.small(11))
                        .foregroundColor(themeModel.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(themeModel.accent.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .contentShape(Rectangle())
        .padding(themeModel.spacingMD)
        .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
    }
}

#Preview {
    OrdersView()
}
