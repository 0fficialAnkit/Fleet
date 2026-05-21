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

//                    checklistBanner

                    routesSection
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

                    Image(systemName: "truck.box.fill")
                        .font(.system(size: 40))
//                        .foregroundStyle(themeModel.driverPrimary)
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
//            .background(
//                LinearGradient(
//                    colors: [
//                        themeModel.driverPrimary.opacity(0.35),
//                        themeModel.driverPrimary.opacity(0.15)
//                    ],
//                    startPoint: .topLeading,
//                    endPoint: .bottomTrailing
//                )
//            )
            .padding(0)
            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
    }

    var summaryCardsSection: some View {

        VStack(spacing: themeModel.spacingMD) {
            HStack(spacing: themeModel.spacingMD) {
                MetricCard(icon: "arrow.triangle.swap", value: "2", label: "Trips Today", color: themeModel.success)
                MetricCard(icon: "point.topleft.down.to.point.bottomright.curvepath", value: "89", label: "KM Driven", color: themeModel.warning)
            }
            
            HStack(spacing: themeModel.spacingMD) {
                MetricCard(icon: "timer", value: "4.5", label: "Hours Active", color: themeModel.analyticsPurple)
                MetricCard(icon: "heart.text.clipboard", value: "Good", label: "Vehicle Health", color: themeModel.danger)
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

    var routesSection: some View {

        VStack(alignment: .leading, spacing: themeModel.spacingMD) {

            SectionHeader(title: "Today's Routes")

            ForEach(trips) { trip in

                
                    VStack(alignment: .leading, spacing: themeModel.spacingMD) {

                        HStack {

                            Text("T-4821")
                                .font(themeModel.headline())
                                .foregroundStyle(themeModel.driverPrimary)

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

                            Button(action: {
                                // Navigation action
                            }) {
                                Text("Navigate")
                                    .font(themeModel.bodyMedium())
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(themeModel.driverPrimary)
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
    }
}
