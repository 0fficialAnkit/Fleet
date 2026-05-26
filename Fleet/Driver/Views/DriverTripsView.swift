import SwiftUI
import Supabase

struct DriverTripsView: View {

    @State private var viewModel = DriverTripsViewModel()
    @State private var selectedFilter: TripFilter = .all
    @Environment(AuthViewModel.self) private var authViewModel

    enum TripFilter: String, CaseIterable {
        case all = "All"
        case remaining = "Remaining"
        case completed = "Completed"
    }

    var filteredTrips: [Trip] {
        switch selectedFilter {
        case .all:
            return viewModel.sortedTrips
        case .remaining:
            return viewModel.sortedTrips.filter { $0.status == .scheduled || $0.status == .active }
        case .completed:
            return viewModel.sortedTrips.filter { $0.status == .completed }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBubbles

                if viewModel.isLoading && viewModel.trips.isEmpty {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: themeModel.driverPrimary))
                    Spacer()
                } else if filteredTrips.isEmpty {
                    Spacer()
                    VStack(spacing: themeModel.spacingSM) {
                        Image(systemName: "road.lanes")
                            .font(.system(size: 40))
                            .foregroundStyle(themeModel.textTertiary)
                        Text("No trips found")
                            .font(themeModel.body())
                            .foregroundStyle(themeModel.textSecondary)
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: themeModel.spacingMD) {
                            ForEach(filteredTrips) { trip in
                                NavigationLink(destination: TripDetailView(
                                    trip: trip,
                                    onStart: { id, vId, notes, urls in viewModel.startTrip(id: id, vehicleId: vId, notes: notes, imageUrls: urls) },
                                    onEnd:   { id, vId, notes, urls in viewModel.endTrip(id: id, vehicleId: vId, notes: notes, imageUrls: urls) }
                                )) {
                                    EnrichedTripCard(
                                        trip: trip,
                                        route: viewModel.routeForTrip(trip),
                                        vehicle: viewModel.vehicleForTrip(trip)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, themeModel.spacingMD)
                        .padding(.vertical, themeModel.spacingSM)
                    }
                }
            }
            .background(themeModel.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Assigned Routes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    NavigationLink(destination: NotificationsView()) {
                        Image(systemName: "bell.badge")
                            .font(.title3)
                            .foregroundStyle(themeModel.driverPrimary)
                    }

                    NavigationLink(destination: DriverProfileView()) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundStyle(themeModel.driverPrimary)
                    }
                }
            }
            .task {
                viewModel.currentUserId = authViewModel.currentUser?.id
                await viewModel.loadData()
                viewModel.setupRealtime()
            }
        }
    }

    // MARK: - Filter Bubbles

    private var filterBubbles: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TripFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue)
                        .font(themeModel.bodyMedium())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedFilter == filter ? themeModel.driverPrimary : Color.gray.opacity(0.15))
                        )
                        .foregroundStyle(selectedFilter == filter ? .white : themeModel.textPrimary)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedFilter = filter
                            }
                        }
                }
            }
            .padding(.horizontal, themeModel.spacingMD)
            .padding(.vertical, 10)
        }
    }
}

#Preview {
    NavigationStack {
        DriverTripsView()
            .environment(AuthViewModel())
    }
}
