import SwiftUI

struct DriverDashboardView: View {

    @State private var viewModel = DriverDashboardViewModel()

    @State private var showCalendar = false

    private let workedDays: Set<Int> = [
        1, 2, 3, 5, 6, 8, 10, 11, 14, 15, 17
    ]

    private let absentDays: Set<Int> = [
        4, 7, 9, 12
    ]

    var vehicle: Vehicle { viewModel.vehicle }
    var trips: [Trip] { viewModel.todaysTrips }

    var body: some View  {

        NavigationStack {

            ScrollView(showsIndicators: false) {

                VStack(spacing: 28) {

                    headerSection

                    vehicleCard

                    summaryCardsSection

                    checklistBanner

                    routesSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 100)
            }
            .background(
                themeModel.backgroundPrimary
                    .ignoresSafeArea()
            )
            .toolbar {

                ToolbarItem(placement: .topBarTrailing) {

                    Button(action: {

                    }) {

                        ZStack {

                            Circle()
                                .fill(themeModel.backgroundElevated.opacity(0.9))
                                .frame(width: 38, height: 38)

                            Image(systemName: "bell.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(themeModel.textPrimary)
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

// MARK: - Header Section

extension DriverDashboardView {

    var headerSection: some View {

        VStack(alignment: .leading, spacing: 6) {

            Text("Good Morning")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(themeModel.textSecondary)

            Text("Driver Portal")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(themeModel.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Vehicle Card

extension DriverDashboardView {

    var vehicleCard: some View {

        VStack(alignment: .leading, spacing: 22) {

            HStack(alignment: .top) {

                VStack(alignment: .leading, spacing: 8) {

                    Text("Assigned Vehicle")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(themeModel.textSecondary)

                    Text("\(vehicle.make ?? "") \(vehicle.model ?? "")")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(themeModel.textPrimary)

                    Text(vehicle.licensePlate ?? "")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(themeModel.info.opacity(0.9))
                }

                Spacer()

                Image(systemName: "box.truck.2.fill")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(themeModel.info.opacity(0.85))
            }

            Divider()
                .overlay(themeModel.divider.opacity(0.4))

            HStack {

                vehicleInfoItem(
                    title: "Fuel",
                    value: "72%",
                    icon: "fuelpump.circle"
                )

                Spacer()

                vehicleInfoItem(
                    title: "Range",
                    value: "48.2 km",
                    icon: "road.lanes"
                )

                Spacer()

                vehicleInfoItem(
                    title: "Health",
                    value: "Excellent",
                    icon: "checkmark.shield"
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(themeModel.backgroundElevated.opacity(0.9))
        )
    }

    func vehicleInfoItem(
        title: String,
        value: String,
        icon: String
    ) -> some View {

        VStack(alignment: .leading, spacing: 6) {

            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(themeModel.textSecondary)

            Text(value)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(themeModel.textPrimary)
        }
    }
}

// MARK: - Summary Cards

extension DriverDashboardView {

    var summaryCardsSection: some View {

        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: 16
        ) {

            refinedSummaryCard(
                title: "Trips Today",
                value: "2",
                icon: "steeringwheel"
            )

            refinedSummaryCard(
                title: "Distance",
                value: "89 km",
                icon: "point.topleft.down.curvedto.point.bottomright.up"
            )

            refinedSummaryCard(
                title: "Hours Active",
                value: "4.5 hrs",
                icon: "timer"
            )

            refinedSummaryCard(
                title: "Vehicle Health",
                value: "Excellent",
                icon: "checkmark.shield.fill"
            )
        }
    }

    func refinedSummaryCard(
        title: String,
        value: String,
        icon: String
    ) -> some View {

        VStack(alignment: .leading, spacing: 18) {

            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(themeModel.info.opacity(0.85))

            VStack(alignment: .leading, spacing: 4) {

                Text(value)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(themeModel.textPrimary)

                Text(title)
                    .font(.system(size: 14))
                    .foregroundStyle(themeModel.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(themeModel.backgroundElevated.opacity(0.85))
        )
    }
}

// MARK: - Checklist Banner

extension DriverDashboardView {

    var checklistBanner: some View {

        HStack(spacing: 14) {

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(Color.green)

            VStack(alignment: .leading, spacing: 4) {

                Text("Pre-trip checklist completed")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(themeModel.textPrimary)

                Text("8/8 items verified • Updated just now")
                    .font(.system(size: 13))
                    .foregroundStyle(themeModel.textSecondary)
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.green.opacity(0.12))
        )
    }
}


// MARK: - Routes Section

extension DriverDashboardView {

    var routesSection: some View {

        VStack(alignment: .leading, spacing: 18) {

            Text("Today's Routes")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(themeModel.textPrimary)

            ForEach(trips) { trip in

                VStack(alignment: .leading, spacing: 18) {

                    HStack {

                        Text("T-4821")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(themeModel.info)

                        Spacer()

                        Label("09:00 AM", systemImage: "calendar.badge.clock")
                            .font(.system(size: 14))
                            .foregroundStyle(themeModel.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 12) {

                        HStack(spacing: 12) {

                            Circle()
                                .fill(Color.green)
                                .frame(width: 10, height: 10)

                            Text("Warehouse A")
                                .font(.system(size: 16))
                                .foregroundStyle(themeModel.textPrimary)
                        }

                        HStack(spacing: 12) {

                            Circle()
                                .fill(Color.red.opacity(0.85))
                                .frame(width: 10, height: 10)

                            Text("Distribution Center")
                                .font(.system(size: 16))
                                .foregroundStyle(themeModel.textPrimary)
                        }
                    }

                    HStack {

                        Text("42 km • 58 mins")
                            .font(.system(size: 14))
                            .foregroundStyle(themeModel.textSecondary)

                        Spacer()

                        Button(action: {

                        }) {

                            Label("Start Trip", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(themeModel.info.opacity(0.9))
                    }
                }
                .padding(22)
                .background(
                    RoundedRectangle(cornerRadius: 26)
                        .fill(themeModel.backgroundElevated.opacity(0.88))
                )
            }
        }
    }
}
