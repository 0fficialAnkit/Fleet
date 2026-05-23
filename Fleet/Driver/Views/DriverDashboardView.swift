import SwiftUI
import Supabase

struct DriverDashboardView: View {

    @State private var viewModel = DriverDashboardViewModel()
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var showingNotifications = false

    var body: some View {

        NavigationStack {

            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()

                if viewModel.isLoading && viewModel.vehicle == nil {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            if let vehicle = viewModel.vehicle {
                                NavigationLink(destination: DriverVehicleDetailView(vehicle: vehicle)) {
                                    vehicleCard(vehicle)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Text("No vehicle assigned.")
                                    .font(themeModel.body())
                                    .foregroundStyle(themeModel.textSecondary)
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
                    HStack(spacing: themeModel.spacingMD) {
                        Button(action: {
                            showingNotifications = true
                        }) {
                            Image(systemName: "bell")
                                .font(.title3)
                                .foregroundStyle(themeModel.textPrimary)
                        }

                        NavigationLink(destination: DriverProfileView()) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.title2)
                                .foregroundStyle(themeModel.driverPrimary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNotifications) {
                NotificationsView()
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
        VStack(alignment: .leading, spacing: themeModel.spacingMD) {

            HStack {

                VStack(alignment: .leading, spacing: themeModel.spacingSM) {

                    Text("Assigned Vehicle")
                        .font(themeModel.bodyMedium())
                        .foregroundStyle(themeModel.textSecondary)

                    Text("\(vehicle.make ?? "") \(vehicle.model ?? "")")
                        .font(themeModel.title())
                        .foregroundStyle(themeModel.textPrimary)

                    Text(vehicle.licensePlate ?? "")
                        .font(themeModel.bodyMedium())
                        .foregroundStyle(themeModel.driverPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: themeModel.spacingSM) {
                    Image(systemName: "truck.box.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(themeModel.driverPrimary.opacity(0.7))
                    HStack(spacing: 4) {
                        Text("View Details")
                            .font(themeModel.caption())
                            .foregroundStyle(themeModel.driverPrimary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(themeModel.driverPrimary)
                    }
                }
            }

            HStack(spacing: themeModel.spacingLG) {

                Label("\(Int(vehicle.mileage ?? 0))km", systemImage: "location.fill")
                    .font(themeModel.bodyMedium())
                    .foregroundStyle(themeModel.driverPrimary)
            }
        }
        .padding(themeModel.spacingMD)
        .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                .stroke(themeModel.driverPrimary.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
    }

    var summaryCardsSection: some View {

        VStack(spacing: themeModel.spacingMD) {
            HStack(spacing: themeModel.spacingMD) {
                MetricCard(icon: "point.topleft.down.to.point.bottomright.curvepath", value: "\(viewModel.todaysTrips.count)", label: "Today's Trips", color: themeModel.warning)
                MetricCard(icon: "timer", value: "\(viewModel.trips.filter { $0.status == .completed }.count)", label: "Completed", color: themeModel.analyticsPurple)
            }
        }
    }

    var tripsSection: some View {

        VStack(alignment: .leading, spacing: themeModel.spacingMD) {

            SectionHeader(title: "Today's Trips")

            if viewModel.todaysTrips.isEmpty {
                Text("No trips scheduled for today.")
                    .font(themeModel.body())
                    .foregroundStyle(themeModel.textSecondary)
            } else {
                ForEach(viewModel.todaysTrips) { trip in
                    NavigationLink {
                        TripDetailView(
                            trip: trip,
                            onStart: { id, vId, notes in viewModel.startTrip(id: id, vehicleId: vId, notes: notes) },
                            onEnd:   { id, vId, notes in viewModel.endTrip(id: id, vehicleId: vId, notes: notes) }
                        )
                    } label: {
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
            case .scheduled: return themeModel.warning
            case .active:    return themeModel.driverPrimary
            case .completed: return themeModel.success
            case .cancelled: return themeModel.danger
            default:         return themeModel.textDisabled
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

        VStack(alignment: .leading, spacing: themeModel.spacingMD) {

            HStack {
                Text("Route #\(trip.id.uuidString.prefix(6).uppercased())")
                    .font(themeModel.headline())
                    .foregroundStyle(themeModel.driverPrimary)

                Spacer()

                StatusBadge(text: statusText, color: statusColor)
            }

            HStack {
                Label(
                    trip.startTime?.formatted(date: .omitted, time: .shortened) ?? "N/A",
                    systemImage: "clock"
                )
                .font(themeModel.caption())
                .foregroundStyle(themeModel.textSecondary)

                Spacer()

                HStack(spacing: 4) {
                    Text("View Details")
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
