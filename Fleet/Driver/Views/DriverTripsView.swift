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
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.green))
                    Spacer()
                } else if filteredTrips.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "road.lanes")
                            .font(.system(size: 40))
                            .foregroundStyle(Color(UIColor.tertiaryLabel))
                        Text("No trips found")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {
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
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Assigned Routes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    NavigationLink(destination: NotificationsView()) {
                        Image(systemName: "bell.badge")
                            .font(.title3)
                            .foregroundStyle(Color.green)
                    }

                    NavigationLink(destination: DriverProfileView()) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.green)
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
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedFilter == filter ? Color.green : Color.gray.opacity(0.15))
                        )
                        .foregroundStyle(selectedFilter == filter ? .white : Color.primary)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedFilter = filter
                            }
                        }
                }
            }
            .padding(.horizontal, 16)
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
