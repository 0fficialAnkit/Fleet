//
//  FleetRows.swift
//  Fleet
//
//  Created by Codex on 19/05/26.
//

import SwiftUI

struct TripRow: View {
    let trip: FleetTrip

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "car.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.blue)
                    .frame(width: 38, height: 38)
                    .background {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(.blue.opacity(0.16))
                    }

                Text(trip.vehicle)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)

                Text(trip.driver)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "location")
                    Text(trip.eta)
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.blue)
            }

            Text(trip.route)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.white.opacity(0.55))

            VStack(spacing: 6) {
                ProgressView(value: trip.progress)
                    .tint(
                        LinearGradient(
                            colors: [.blue, .cyan, .green],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .scaleEffect(x: 1, y: 1.2, anchor: .center)

                HStack {
                    Text("0%")
                    Spacer()
                    Text("\(Int(trip.progress * 100))%")
                        .foregroundStyle(.blue)
                    Spacer()
                    Text("100%")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.50))
            }
        }
        .padding(.vertical, 4)
    }
}

struct AlertRow: View {
    let alert: FleetAlert

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(alert.tint)
                .frame(width: 40, height: 40)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(alert.tint.opacity(0.16))
                }

            VStack(alignment: .leading, spacing: 5) {
                Text(alert.vehicle)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)

                Text(alert.message)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Spacer()

            Text(alert.time)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.white.opacity(0.55))

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white.opacity(0.45))
        }
        .padding(.vertical, 4)
    }
}
