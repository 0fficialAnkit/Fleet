import SwiftUI
import Charts

struct DashboardView: View {

    // MARK: - MOCK DATA

    let vehicle = Vehicle(
        id: UUID(),
        make: "Ford",
        model: "F-150",
        year: 2024,
        vin: nil,
        licensePlate: "TRK-001",
        assignedDriverId: nil,
        status: .active
    )

    let trips: [Trip] = [
        Trip(
            id: UUID(),
            vehicleId: UUID(),
            driverId: UUID(),
            routeId: UUID(),
            startTime: Date(),
            endTime: nil,
            distance: 42,
            status: .scheduled
        )
    ]

    struct SafetyData: Identifiable {

        let id = UUID()
        let day: String
        let value: Double
    }

    let graphData: [SafetyData] = [

        .init(day: "M", value: 90),
        .init(day: "T", value: 92),
        .init(day: "W", value: 91),
        .init(day: "T", value: 95),
        .init(day: "F", value: 96),
        .init(day: "S", value: 94),
        .init(day: "S", value: 96)
    ]

    // MARK: - BODY

    var body: some View {

        NavigationStack {

            ScrollView(showsIndicators: false) {

                VStack(spacing: 22) {

                    topHeader

                    vehicleCard

                    safetyCard

                    statsSection

                    checklistBanner

                    routesSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    DashboardView()
}

// MARK: - COMPONENTS

extension DashboardView {

    // MARK: HEADER

    var topHeader: some View {

        HStack {

            VStack(alignment: .leading, spacing: 6) {

                Text("Good Morning")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Driver Portal")
                    .font(.largeTitle.bold())
            }

            Spacer()

            HStack(spacing: 14) {

                Button {

                } label: {

                    Image(systemName: "bell.badge")
                        .font(.title3)
                        .foregroundStyle(.primary)
                        .frame(width: 46, height: 46)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }

                Button {

                } label: {

                    Image(systemName: "plus")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(Color.green)
                        .clipShape(Circle())
                }
            }
        }
    }

    // MARK: VEHICLE CARD

    var vehicleCard: some View {

        VStack(alignment: .leading, spacing: 20) {

            HStack {

                VStack(alignment: .leading, spacing: 8) {

                    Text("Assigned Vehicle")
                        .foregroundStyle(.secondary)

                    Text("\(vehicle.make ?? "") \(vehicle.model ?? "")")
                        .font(.title.bold())

                    Text(vehicle.licensePlate ?? "")
                        .foregroundStyle(.blue)
                        .fontWeight(.medium)
                }

                Spacer()

                ZStack {

                    RoundedRectangle(
                        cornerRadius: 22,
                        style: .continuous
                    )
                    .fill(.thinMaterial)
                    .frame(width: 72, height: 72)

                    Image(systemName: "truck.box.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.blue)
                }
            }

            HStack(spacing: 24) {

                Label("72% Fuel", systemImage: "fuelpump.fill")
                    .foregroundStyle(.green)

                Label("48.2k km", systemImage: "location.fill")
                    .foregroundStyle(.blue)
            }
            .font(.subheadline.weight(.medium))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.35),
                    Color.indigo.opacity(0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 32,
                style: .continuous
            )
        )
    }

    // MARK: SAFETY CARD

    var safetyCard: some View {

        VStack(alignment: .leading, spacing: 24) {

            HStack(alignment: .top) {

                VStack(alignment: .leading, spacing: 6) {

                    Text("Safety Score")
                        .font(.title3.weight(.semibold))

                    Text("This Week")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {

                    HStack(spacing: 4) {

                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)

                        Text("96")
                            .font(.system(size: 34, weight: .bold))
                    }

                    Text("Excellent")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Chart(graphData) { item in

                AreaMark(
                    x: .value("Day", item.day),
                    y: .value("Score", item.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.green.opacity(0.22),
                            Color.green.opacity(0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Day", item.day),
                    y: .value("Score", item.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(.green)
                .lineStyle(
                    StrokeStyle(
                        lineWidth: 3,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
            }
            .frame(height: 120)
            .chartYScale(domain: 80...100)
            .chartYAxis(.hidden)
            .chartXAxis {

                AxisMarks(position: .bottom) { value in

                    AxisValueLabel {

                        if let day = value.as(String.self) {

                            Text(day)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    AxisGridLine(
                        stroke: StrokeStyle(lineWidth: 0)
                    )
                }
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 32,
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 32,
                style: .continuous
            )
            .stroke(
                Color.white.opacity(0.05),
                lineWidth: 1
            )
        )
    }

    // MARK: STATS

    var statsSection: some View {

        HStack(spacing: 16) {

            statsCard(
                icon: "paperplane.fill",
                value: "2",
                title: "Trips",
                color: .blue
            )

            statsCard(
                icon: "location.fill",
                value: "89",
                title: "KM",
                color: .green
            )

            statsCard(
                icon: "clock.fill",
                value: "4.5h",
                title: "Hours",
                color: .orange
            )
        }
    }

    func statsCard(
        icon: String,
        value: String,
        title: String,
        color: Color
    ) -> some View {

        VStack(spacing: 14) {

            ZStack {

                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .fill(color.opacity(0.15))
                .frame(width: 52, height: 52)

                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
            }

            Text(value)
                .font(.title.bold())

            Text(title)
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.regularMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
        )
    }

    // MARK: CHECKLIST

    var checklistBanner: some View {

        HStack(spacing: 16) {

            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 4) {

                Text("Pre-trip checklist complete")
                    .fontWeight(.semibold)

                Text("8/8 items verified • Today 8:04 AM")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.green.opacity(0.14))
        .clipShape(
            RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
        )
    }

    // MARK: ROUTES

    var routesSection: some View {

        VStack(alignment: .leading, spacing: 18) {

            Text("Today's Routes")
                .font(.title2.bold())

            ForEach(trips) { trip in

                VStack(alignment: .leading, spacing: 20) {

                    HStack {

                        Text("T-4821")
                            .foregroundStyle(.blue)
                            .fontWeight(.semibold)

                        Spacer()

                        Label("09:00 AM", systemImage: "clock")
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 14) {

                        HStack(spacing: 14) {

                            Circle()
                                .fill(.green)
                                .frame(width: 10, height: 10)

                            Text("Warehouse A")
                        }

                        Rectangle()
                            .fill(.gray.opacity(0.4))
                            .frame(width: 1, height: 24)
                            .padding(.leading, 4)

                        HStack(spacing: 14) {

                            Circle()
                                .fill(.red)
                                .frame(width: 10, height: 10)

                            Text("Distribution Center")
                        }
                    }

                    HStack {

                        Text("42 km")
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button {

                        } label: {

                            Text("Navigate")
                                .fontWeight(.semibold)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(22)
                .background(.regularMaterial)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 30,
                        style: .continuous
                    )
                )
            }
        }
    }
}
