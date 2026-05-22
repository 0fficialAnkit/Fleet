//
//  FleetDashboardView.swift
//  Fleet
//
//  Created by Codex on 19/05/26.
//

import SwiftUI

struct FleetDashboardView: View {
    @Namespace private var glassNamespace

    private let stats = FleetSampleData.stats
    private let utilization = FleetSampleData.utilization
    private let trips = FleetSampleData.trips
    private let alerts = FleetSampleData.alerts

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                FleetDashboardBackground()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 26) {
                        overviewHeader
                        statGrid
                        fuelCard
                        utilizationCard
                        tripsCard
                        alertsCard
                        trackingCard
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, max(proxy.safeAreaInsets.top - 8, 8))
                    .padding(.bottom, 34)
                }
            }
        }
    }

    private var overviewHeader: some View {
        HStack(alignment: .center, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Fleet Overview")
                    .font(.system(size: 31, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.88)

                Text("Good Morning")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.white.opacity(0.55))
            }

            Spacer(minLength: 10)

            Button { } label: {
                Image(systemName: "bell")
                    .font(.system(size: 20, weight: .medium))
                    .frame(width: 50, height: 50)
            }
            .buttonStyle(.glass(.clear.interactive()))
            .tint(.white)
            .glassEffectID("notification-button", in: glassNamespace)
        }
    }

    private var statGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
            ForEach(stats) { stat in
                StatTile(stat: stat)
                    .glassEffect(.regular.tint(stat.tint.opacity(0.10)).interactive(), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .glassEffectID(stat.id, in: glassNamespace)
            }
        }
    }

    private var fuelCard: some View {
        LiquidPanel {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fuel Consumption")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)

                        Text("This week - 1,900L total")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(.white.opacity(0.55))
                    }

                    Spacer()

                    Text("-8%")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .glassEffect(.regular.tint(.blue.opacity(0.24)).interactive(), in: Capsule())
                }

                FleetLineChart(values: FleetSampleData.fuelTrend)
                    .frame(height: 126)

                HStack {
                    ForEach(["Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                        Text(day)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.48))
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private var utilizationCard: some View {
        LiquidPanel {
            VStack(alignment: .leading, spacing: 26) {
                HStack {
                    Text("Vehicle Utilization")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    Text("Today")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.white.opacity(0.58))
                }

                HStack(alignment: .bottom, spacing: 18) {
                    ForEach(utilization) { bar in
                        VStack(spacing: 10) {
                            Capsule()
                                .fill(.green.gradient)
                                .frame(width: 13, height: max(14, 90 * bar.value))

                            Text(bar.label)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(.white.opacity(0.54))
                        }
                        .frame(maxWidth: .infinity, alignment: .bottom)
                    }
                }
                .frame(height: 118, alignment: .bottom)
            }
        }
    }

    private var tripsCard: some View {
        LiquidPanel {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Active Trips")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    HStack(spacing: 6) {
                        Circle()
                            .fill(.green)
                            .frame(width: 10, height: 10)
                        Text("Live")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.green)
                }

                ForEach(trips) { trip in
                    TripRow(trip: trip)

                    if trip.id != trips.last?.id {
                        Divider()
                            .overlay(.white.opacity(0.07))
                    }
                }
            }
        }
    }

    private var alertsCard: some View {
        LiquidPanel {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Alerts")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    Text("3 active")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.pink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .glassEffect(.regular.tint(.pink.opacity(0.22)).interactive(), in: Capsule())
                }

                ForEach(alerts) { alert in
                    AlertRow(alert: alert)

                    if alert.id != alerts.last?.id {
                        Divider()
                            .overlay(.white.opacity(0.07))
                    }
                }
            }
        }
    }

    private var trackingCard: some View {
        TrackingCard()
            .glassEffectID("tracking", in: glassNamespace)
    }
}
