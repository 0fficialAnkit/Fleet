//
//  FleetSharedComponents.swift
//  Fleet
//
//  Created by Codex on 19/05/26.
//

import SwiftUI

struct FleetDashboardBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.02, green: 0.02, blue: 0.04),
                Color(red: 0.03, green: 0.03, blue: 0.07),
                Color(red: 0.01, green: 0.01, blue: 0.02)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay {
            LinearGradient(
                colors: [
                    .blue.opacity(0.18),
                    .clear,
                    .green.opacity(0.06)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
        .ignoresSafeArea()
    }
}

struct LiquidPanel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.white.opacity(0.055))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.10), lineWidth: 1)
            }
            .glassEffect(.regular.tint(.white.opacity(0.08)).interactive(), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

struct StatTile: View {
    let stat: FleetStat

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: stat.symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(stat.tint)
                .frame(width: 44, height: 44)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(stat.tint.opacity(0.16))
                }

            VStack(alignment: .leading, spacing: 8) {
                Text(stat.value)
                    .font(.system(size: 29, weight: .semibold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.72)
                    .lineLimit(1)

                Text(stat.title)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.white.opacity(0.56))

                Text(stat.change)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(stat.tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, minHeight: 178, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.white.opacity(0.055))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        }
    }
}

struct TrackingCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bolt")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(.blue)
                .padding(.top, 8)

            Text("Live Vehicle Tracking")
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(.white)

            Text("24 vehicles active on route")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.white.opacity(0.58))

            HStack(spacing: 8) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(.green.opacity(index == 3 ? 0.95 : 0.65))
                        .frame(width: 14, height: 14)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.24),
                            Color.cyan.opacity(0.10),
                            Color.indigo.opacity(0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        }
        .glassEffect(.regular.tint(.blue.opacity(0.20)).interactive(), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}
