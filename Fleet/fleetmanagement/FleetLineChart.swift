//
//  FleetLineChart.swift
//  Fleet
//
//  Created by Codex on 19/05/26.
//

import SwiftUI

struct FleetLineChart: View {
    let values: [Double]

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let points = values.enumerated().map { index, value in
                CGPoint(
                    x: size.width * CGFloat(index) / CGFloat(max(values.count - 1, 1)),
                    y: size.height * CGFloat(1 - value)
                )
            }

            ZStack {
                chartFill(points: points, size: size)
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.28), .blue.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                chartLine(points: points)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .cyan, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )
            }
        }
    }

    private func chartLine(points: [CGPoint]) -> Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: first)

            for index in points.indices.dropFirst() {
                let previous = points[index - 1]
                let current = points[index]
                let midpoint = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2)
                path.addQuadCurve(to: midpoint, control: previous)
                path.addQuadCurve(to: current, control: midpoint)
            }
        }
    }

    private func chartFill(points: [CGPoint], size: CGSize) -> Path {
        var path = chartLine(points: points)
        if let last = points.last, let first = points.first {
            path.addLine(to: CGPoint(x: last.x, y: size.height))
            path.addLine(to: CGPoint(x: first.x, y: size.height))
            path.closeSubpath()
        }
        return path
    }
}
