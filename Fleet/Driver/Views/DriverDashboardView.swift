import SwiftUI

struct DriverDashboardView: View {

    @State private var viewModel = DriverDashboardViewModel()

    var vehicle: Vehicle { viewModel.vehicle }
    var trips: [Trip] { viewModel.todaysTrips }

    var body: some View {

        NavigationStack {

            ScrollView(showsIndicators: false) {

                VStack(spacing: 20) {

                    vehicleCard

                    summaryCardsSection

                    checklistBanner

                    routesSection
                }
                .padding()
            }
            .background(themeModel.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Driver Portal")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Action for notifications
                    }) {
                        Image(systemName: "bell")
                            .font(.title3)
                            .foregroundStyle(themeModel.textPrimary)
                    }
                }
            }
        }
    }
}

#Preview {
    DriverDashboardView()
}

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
                        .foregroundStyle(themeModel.info)
                }

                Spacer()

                Image(systemName: "truck.box.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(themeModel.info)
            }

            HStack(spacing: themeModel.spacingLG) {

                Label("72% Fuel", systemImage: "fuelpump.fill")
                    .font(themeModel.bodyMedium())
                    .foregroundStyle(themeModel.success)

                Label("48.2k km", systemImage: "location.fill")
                    .font(themeModel.bodyMedium())
                    .foregroundStyle(themeModel.info)
            }
        }
        .padding(themeModel.spacingMD)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    themeModel.info.opacity(0.4),
                    themeModel.infoDark.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusXL))
    }



    var summaryCardsSection: some View {

        VStack(spacing: themeModel.spacingMD) {
            HStack(spacing: themeModel.spacingMD) {
                SummaryCard(title: "Trips Today", count: "2", icon: "paperplane.fill", color: themeModel.success)
                SummaryCard(title: "KM Driven", count: "89", icon: "location.fill", color: themeModel.warning)
            }
            
            HStack(spacing: themeModel.spacingMD) {
                SummaryCard(title: "Hours Active", count: "4.5", icon: "clock.fill", color: themeModel.analyticsPurple)
                SummaryCard(title: "Vehicle Health", count: "Good", icon: "waveform.path.ecg", color: themeModel.danger)
            }
        }
    }

    var checklistBanner: some View {

        HStack {

            Image(systemName: "checkmark.circle.fill")
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
        .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusLG))
    }

    var routesSection: some View {

        VStack(alignment: .leading, spacing: themeModel.spacingMD) {

            Text("Today's Routes")
                .font(themeModel.title(22))
                .foregroundStyle(themeModel.textPrimary)

            ForEach(trips) { trip in

                VStack(alignment: .leading, spacing: themeModel.spacingMD) {

                    HStack {

                        Text("T-4821")
                            .font(themeModel.headline())
                            .foregroundStyle(themeModel.info)

                        Spacer()

                        Label("09:00 AM", systemImage: "clock")
                            .font(themeModel.bodyMedium())
                            .foregroundStyle(themeModel.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 12) {

                        HStack {
                            Circle()
                                .fill(themeModel.success)
                                .frame(width: 10)

                            Text("Warehouse A")
                                .font(themeModel.body())
                                .foregroundStyle(themeModel.textPrimary)
                        }

                        Rectangle()
                            .fill(themeModel.divider)
                            .frame(width: 1, height: 20)
                            .padding(.leading, 4)

                        HStack {
                            Circle()
                                .fill(themeModel.danger)
                                .frame(width: 10)

                            Text("Distribution Center")
                                .font(themeModel.body())
                                .foregroundStyle(themeModel.textPrimary)
                        }
                    }

                    HStack {

                        Text("42 km")
                            .font(themeModel.bodyMedium())
                            .foregroundStyle(themeModel.textSecondary)

                        Spacer()

                        Button("Navigate") {

                        }
                        .buttonStyle(.borderedProminent)
                        .tint(themeModel.info)
                    }
                }
                .padding(themeModel.spacingMD)
                .background(themeModel.backgroundElevated)
                .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusLG))
            }
        }
    }
}
