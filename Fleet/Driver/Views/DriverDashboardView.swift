import SwiftUI

struct DriverDashboardView: View {

    @State private var viewModel = DriverDashboardViewModel()

    var vehicle: Vehicle { viewModel.vehicle }
    var trips: [Trip] { viewModel.todaysTrips }

    var body: some View {

        NavigationStack {

            ScrollView(showsIndicators: false) {

                VStack(spacing: 20) {

                    NavigationLink(destination: DriverVehicleDetailView(vehicle: vehicle)) {
                        vehicleCard
                    }
                    .buttonStyle(.plain)

                    summaryCardsSection

//                    checklistBanner

                    tripsSection
                }
                .padding()
            }
            .background(themeModel.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Driver Portal")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: themeModel.spacingMD) {
                        Button(action: {
                            // Action for notifications
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
        }
    }
}

#Preview {
    DriverDashboardView()
}

// MARK: - Subviews

extension DriverDashboardView {

    var vehicleCard: some View {
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

                Label("72% Fuel", systemImage: "fuelpump.fill")
                    .font(themeModel.bodyMedium())
                    .foregroundStyle(themeModel.success)

                Label("48.2k km", systemImage: "location.fill")
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
                MetricCard(icon: "point.topleft.down.to.point.bottomright.curvepath", value: "89", label: "KM Driven", color: themeModel.warning)
                MetricCard(icon: "timer", value: "4.5", label: "Hours Active", color: themeModel.analyticsPurple)
            }
        }
    }

    var checklistBanner: some View {

        HStack {

            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(themeModel.success)
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {

                Text("Pre-trip checklist complete")
                    .font(themeModel.headline())
                    .foregroundStyle(themeModel.textPrimary)

                Text("8/8 items verified")
                    .font(themeModel.caption())
                    .foregroundStyle(themeModel.textSecondary)
            }

            Spacer()
        }
        .padding(themeModel.spacingMD)
        .background(themeModel.success.opacity(0.15))
        .padding(0)
        .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
    }

    var tripsSection: some View {

        VStack(alignment: .leading, spacing: themeModel.spacingMD) {

            SectionHeader(title: "Today's Trips")

            ForEach(trips) { trip in
                NavigationLink {
                    TripDetailView(
                        trip: trip,
                        onStart: { id in viewModel.startTrip(id: id) },
                        onEnd:   { id in viewModel.endTrip(id: id) }
                    )
                } label: {
                    tripCard(trip)
                }
                .buttonStyle(.plain)
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

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Circle().fill(themeModel.success).frame(width: 10)
                    Text("Warehouse A, Sector 12")
                        .font(themeModel.body())
                        .foregroundStyle(themeModel.textPrimary)
                }

                Rectangle()
                    .fill(themeModel.divider)
                    .frame(width: 1, height: 18)
                    .padding(.leading, 4)

                HStack(spacing: 8) {
                    Circle().fill(themeModel.danger).frame(width: 10)
                    Text("Distribution Center, Zone B")
                        .font(themeModel.body())
                        .foregroundStyle(themeModel.textPrimary)
                }
            }

            HStack {
                Label(
                    trip.startTime?.formatted(date: .omitted, time: .shortened) ?? "09:00 AM",
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
