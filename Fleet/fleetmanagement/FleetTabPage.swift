//
//  FleetTabPage.swift
//  Fleet
//
//  Created by Codex on 19/05/26.
//

import SwiftUI

struct FleetTabPage: View {
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color

    var body: some View {
        ZStack {
            FleetDashboardBackground()

            VStack(spacing: 22) {
                Image(systemName: symbol)
                    .font(.system(size: 46, weight: .medium))
                    .foregroundStyle(tint)
                    .frame(width: 86, height: 86)
                    .background {
                        Circle()
                            .fill(tint.opacity(0.15))
                    }
                    .glassEffect(.regular.tint(tint.opacity(0.18)).interactive(), in: Circle())

                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.58))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(.white.opacity(0.055))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(.white.opacity(0.10), lineWidth: 1)
            }
            .glassEffect(.regular.tint(tint.opacity(0.08)).interactive(), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            .padding(.horizontal, 24)
        }
    }
}
