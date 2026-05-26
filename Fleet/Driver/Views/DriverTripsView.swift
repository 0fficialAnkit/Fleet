import SwiftUI
import Supabase

struct DriverTripsView: View {

    @State private var viewModel = DriverTripsViewModel()
    @State private var selectedFilter: TripFilter = .all
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var navigationPath = [DriverDestination]()

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

    var filterBubbles: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TripFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue)
                        .font(.body.weight(.medium))
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
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                filterBubbles

                if viewModel.isLoading && viewModel.trips.isEmpty {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                } else if filteredTrips.isEmpty {
                    Spacer()
                    Text("No trips found.")
                        .font(.body)
                        .foregroundStyle(Color.secondary)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(filteredTrips) { trip in
                                NavigationLink(value: DriverDestination.tripDetail(trip)) {
                                    DriverTripCardView(trip: trip)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Assigned Routes")
            .navigationDestination(for: DriverDestination.self) { destination in
                switch destination {
                case .tripDetail(let t):
                    TripDetailView(
                        trip: t,
                        onStart: { id, vId, notes in viewModel.startTrip(id: id, vehicleId: vId, notes: notes) },
                        onEnd:   { id, vId, notes in viewModel.endTrip(id: id, vehicleId: vId, notes: notes) }
                    )
                default:
                    EmptyView()
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

// MARK: - Card (display only, no state)

struct DriverTripCardView: View {
    let trip: Trip

    var statusColor: Color {
        switch trip.status {
        case .scheduled: return Color.yellow
        case .active:    return Color.green
        case .completed: return Color.green
        case .cancelled: return Color.red
        case .none:      return Color(.quaternaryLabel)
        }
    }

    var statusText: String {
        switch trip.status {
        case .scheduled: return "Pending"
        case .active:    return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .none:      return "Unknown"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack {
                Text("Route #\(trip.id.uuidString.prefix(6).uppercased())")
                    .font(.headline)
                    .foregroundStyle(Color.primary)

                Spacer()

                StatusBadge(text: statusText, color: statusColor)
            }

            HStack {
                Label(
                    trip.startTime?.formatted(date: .omitted, time: .shortened) ?? "N/A",
                    systemImage: "clock"
                )
                .font(.footnote)
                .foregroundStyle(Color(.tertiaryLabel))

                Spacer()

                HStack(spacing: 4) {
                    Text("Tap for details")
                        .font(.footnote)
                        .foregroundStyle(Color.green)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.green)
                }
            }
        }
        .padding(16)
        .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        )

    }
}

#Preview {
    DriverTripsView()
        .environment(AuthViewModel())
}