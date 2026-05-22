import SwiftUI

struct DriverTripsView: View {

    @State private var viewModel = DriverTripsViewModel()
    @State private var selectedFilter: TripFilter = .all

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
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBubbles

                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(filteredTrips) { trip in
                            NavigationLink {
                                TripDetailView(
                                    trip: trip,
                                    onStart: { id in viewModel.startTrip(id: id) },
                                    onEnd:   { id in viewModel.endTrip(id: id) }
                                )
                            } label: {
                                DriverTripCardView(trip: trip)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .background(themeModel.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Assigned Routes")
        }
    }
}

// MARK: - Card (display only, no state)

struct DriverTripCardView: View {
    let trip: Trip

    var statusColor: Color {
        switch trip.status {
        case .scheduled: return themeModel.warning
        case .active:    return themeModel.driverPrimary
        case .completed: return themeModel.success
        case .cancelled: return themeModel.danger
        case .none:      return themeModel.textDisabled
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
        VStack(alignment: .leading, spacing: themeModel.spacingMD) {

            HStack {
                Text("Route #\(trip.id.uuidString.prefix(6).uppercased())")
                    .font(themeModel.headline())
                    .foregroundStyle(themeModel.textPrimary)

                Spacer()

                StatusBadge(text: statusText, color: statusColor)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(themeModel.success)
                    Text("Warehouse A, Sector 12")
                        .font(themeModel.bodyMedium())
                        .foregroundStyle(themeModel.textSecondary)
                }

                Rectangle()
                    .fill(themeModel.divider)
                    .frame(width: 2, height: 16)
                    .padding(.leading, 3)

                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(themeModel.danger)
                    Text("Distribution Center, Zone B")
                        .font(themeModel.bodyMedium())
                        .foregroundStyle(themeModel.textPrimary)
                }
            }
            .padding(.vertical, 2)

            HStack {
                Label(
                    trip.startTime?.formatted(date: .omitted, time: .shortened) ?? "N/A",
                    systemImage: "clock"
                )
                .font(themeModel.caption())
                .foregroundStyle(themeModel.textTertiary)

                Spacer()

                HStack(spacing: 4) {
                    Text("Tap for details")
                        .font(themeModel.caption())
                        .foregroundStyle(themeModel.driverPrimary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(themeModel.driverPrimary)
                }
            }
        }
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
    DriverTripsView()
}
