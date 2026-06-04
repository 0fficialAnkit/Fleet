// DriverCarbonDashboardView.swift
// Fleet
//
// Carbon Score Dashboard for Drivers.

import SwiftUI

struct DriverCarbonDashboardView: View {
    let carbonScore: Int
    let totalEmissions: Double
    let totalDistance: Double
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Carbon Score Widget
                VStack(spacing: 12) {
                    Text("Your Carbon Score")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 15)
                            .frame(width: 150, height: 150)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(carbonScore) / 100.0)
                            .stroke(scoreColor, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                            .frame(width: 150, height: 150)
                            .rotationEffect(.degrees(-90))
                        
                        VStack {
                            Text("\(carbonScore)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundStyle(scoreColor)
                            Text("/ 100")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Text(scoreMessage)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                
                // Stats Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    statCard(
                        title: "Total CO2",
                        value: String(format: "%.1f kg", totalEmissions),
                        icon: "cloud.fill",
                        color: .gray
                    )
                    
                    let emissionRate = totalDistance > 0 ? (totalEmissions / totalDistance) : 0.0
                    statCard(
                        title: "Avg Rate",
                        value: String(format: "%.2f kg/km", emissionRate),
                        icon: "speedometer",
                        color: .blue
                    )
                }
                .padding(.horizontal)
                
                // Eco Driving Tips
                VStack(alignment: .leading, spacing: 16) {
                    Text("Eco-Driving Tips")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        tipRow(icon: "hare.fill", text: "Avoid rapid acceleration and hard braking.")
                        tipRow(icon: "engine.combustion", text: "Turn off your engine if idling for more than a minute.")
                        tipRow(icon: "gauge.with.dots.needle.bottom.50percent", text: "Maintain a steady speed and use cruise control on highways.")
                        tipRow(icon: "wind", text: "Keep windows closed at high speeds to reduce drag.")
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Eco Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var scoreColor: Color {
        if carbonScore >= 80 { return .green }
        if carbonScore >= 50 { return .orange }
        return .red
    }
    
    private var scoreMessage: String {
        if carbonScore >= 80 { return "Excellent eco-driving! You are minimizing your carbon footprint." }
        if carbonScore >= 50 { return "Good job, but there is room for improvement in fuel efficiency." }
        return "High emissions detected. Please review eco-driving tips to improve."
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.green)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}
