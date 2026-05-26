import SwiftUI
import Supabase

struct DriverDashboardView: View {

    @State private var viewModel = DriverDashboardViewModel()
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var showingNotifications = false
    @State private var navigationPath = [DriverDestination]()

    var body: some View {

        NavigationStack(path: $navigationPath) {

            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if viewModel.isLoading && viewModel.vehicle == nil {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            if let vehicle = viewModel.vehicle {
                                NavigationLink(value: DriverDestination.vehicleDetail(vehicle)) {
                                    vehicleCard(vehicle)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Text("No vehicle assigned.")
                                    .font(.body)
                                    .foregroundStyle(Color.secondary)
                                    .padding()
                            }

                            summaryCardsSection

                            tripsSection
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Driver Portal")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            showingNotifications = true
                        }) {
                            Image(systemName: "bell")
                                .font(.title3)
                                .foregroundStyle(Color.primary)
                        }

                        NavigationLink(value: DriverDestination.profile) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.green)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNotifications) {
                NotificationsView()
            }
            .navigationDestination(for: DriverDestination.self) { destination in
                switch destination {
                case .profile:
                    DriverProfileView()
                case .vehicleDetail(let v):
                    DriverVehicleDetailView(vehicle: v)
                case .tripDetail(let t):
                    TripDetailView(
                        trip: t,
                        onStart: { id, vId, notes in viewModel.startTrip(id: id, vehicleId: vId, notes: notes) },
                        onEnd:   { id, vId, notes in viewModel.endTrip(id: id, vehicleId: vId, notes: notes) }
                    )
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

#Preview {
    DriverDashboardView()
        .environment(AuthViewModel())
}

// MARK: - Subviews

extension DriverDashboardView {

    func vehicleCard(_ vehicle: Vehicle) -> some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack {

                VStack(alignment: .leading, spacing: 8) {

                    Text("Assigned Vehicle")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.secondary)

                    Text("\(vehicle.make ?? "") \(vehicle.model ?? "")")
                        .font(.title.bold())
                        .foregroundStyle(Color.primary)

                    Text(vehicle.licensePlate ?? "")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.green)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Image(systemName: "truck.box.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.green.opacity(0.7))
                    HStack(spacing: 4) {
                        Text("View Details")
                            .font(.footnote)
                            .foregroundStyle(Color.green)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.green)
                    }
                }
            }

            HStack(spacing: 24) {

                Label("\(Int(vehicle.mileage ?? 0))km", systemImage: "location.fill")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.green)
            }
        }
        .padding(16)
        .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )

    }

    var summaryCardsSection: some View {

        VStack(spacing: 16) {
            HStack(spacing: 16) {
                MetricCard(icon: "point.topleft.down.to.point.bottomright.curvepath", value: "\(viewModel.todaysTrips.count)", label: "Today's Trips", color: Color.yellow)
                MetricCard(icon: "timer", value: "\(viewModel.trips.filter { $0.status == .completed }.count)", label: "Completed", color: Color.purple)
            }
        }
    }

    var tripsSection: some View {

        VStack(alignment: .leading, spacing: 16) {

            SectionHeader(title: "Today's Trips")

            if viewModel.todaysTrips.isEmpty {
                Text("No trips scheduled for today.")
                    .font(.body)
                    .foregroundStyle(Color.secondary)
            } else {
                ForEach(viewModel.todaysTrips) { trip in
                    NavigationLink(value: DriverDestination.tripDetail(trip)) {
                        tripCard(trip)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    func tripCard(_ trip: Trip) -> some View {
        let statusColor: Color = {
            switch trip.status {
            case .scheduled: return Color.yellow
            case .active:    return Color.green
            case .completed: return Color.green
            case .cancelled: return Color.red
            default:         return Color(.quaternaryLabel)
            }
        }()

        let statusText: String = {
            switch trip.status {
            case .scheduled: return "Pending"
            case .active:    return "In Progress"
            case .completed: return "Completed"
            case .cancelled: return "Cancelled"
            default:         return "Unknown"
            }
        }()

        VStack(alignment: .leading, spacing: 16) {

            HStack {
                Text("Route #\(trip.id.uuidString.prefix(6).uppercased())")
                    .font(.headline)
                    .foregroundStyle(Color.green)

                Spacer()

                StatusBadge(text: statusText, color: statusColor)
            }

            HStack {
                Label(
                    trip.startTime?.formatted(date: .omitted, time: .shortened) ?? "N/A",
                    systemImage: "clock"
                )
                .font(.footnote)
                .foregroundStyle(Color.secondary)

                Spacer()

                HStack(spacing: 4) {
                    Text("View Details")
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