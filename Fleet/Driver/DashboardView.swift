import SwiftUI

struct DashboardView: View {

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

    var body: some View {

        NavigationStack {

            ScrollView(showsIndicators: false) {

                VStack(spacing: 20) {

                    topHeader

                    vehicleCard

                    safetyCard

                    statsSection

                    checklistBanner

                    routesSection
                }
                .padding()
            }
            .background(Color.black)
        }
    }
}

#Preview {
    DashboardView()
}

extension DashboardView {

    var topHeader: some View {

        HStack {

            VStack(alignment: .leading, spacing: 6) {

                Text("Good Morning")
                    .foregroundStyle(.gray)

                Text("Driver Portal")
                    .font(.largeTitle.bold())
            }

            Spacer()

            Button {

            } label: {

                Image(systemName: "bell")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 45, height: 45)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
    }

    var vehicleCard: some View {

        VStack(alignment: .leading, spacing: 18) {

            HStack {

                VStack(alignment: .leading, spacing: 8) {

                    Text("Assigned Vehicle")
                        .foregroundStyle(.gray)

                    Text("\(vehicle.make ?? "") \(vehicle.model ?? "")")
                        .font(.title.bold())

                    Text(vehicle.licensePlate ?? "")
                        .foregroundStyle(.blue)
                }

                Spacer()

                Image(systemName: "truck.box.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue)
            }

            HStack(spacing: 20) {

                Label("72% Fuel", systemImage: "fuelpump.fill")
                    .foregroundStyle(.green)

                Label("48.2k km", systemImage: "location.fill")
                    .foregroundStyle(.blue)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.4),
                    Color.indigo.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 30))
    }

    var safetyCard: some View {

        VStack(alignment: .leading, spacing: 20) {

            HStack {

                VStack(alignment: .leading) {

                    Text("Safety Score")
                        .font(.title2.bold())

                    Text("This week")
                        .foregroundStyle(.gray)
                }

                Spacer()

                HStack {

                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)

                    Text("96")
                        .font(.largeTitle.bold())

                    Text("/100")
                        .foregroundStyle(.green)
                }
            }

            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            .green.opacity(0.6),
                            .green.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 100)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 30))
    }

    var statsSection: some View {

        HStack(spacing: 16) {

            statsCard(
                icon: "paperplane.fill",
                value: "2",
                title: "Trips Today",
                color: .blue
            )

            statsCard(
                icon: "location.fill",
                value: "89",
                title: "KM Driven",
                color: .green
            )

            statsCard(
                icon: "clock.fill",
                value: "4.5h",
                title: "Hours Active",
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

            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title2)

            Text(value)
                .font(.title.bold())

            Text(title)
                .foregroundStyle(.gray)
                .font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }

    var checklistBanner: some View {

        HStack {

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title)

            VStack(alignment: .leading, spacing: 6) {

                Text("Pre-trip checklist complete")
                    .fontWeight(.semibold)

                Text("8/8 items verified")
                    .foregroundStyle(.gray)
            }

            Spacer()
        }
        .padding()
        .background(Color.green.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }

    var routesSection: some View {

        VStack(alignment: .leading, spacing: 16) {

            Text("Today's Routes")
                .font(.title2.bold())

            ForEach(trips) { trip in

                VStack(alignment: .leading, spacing: 16) {

                    HStack {

                        Text("T-4821")
                            .foregroundStyle(.blue)
                            .fontWeight(.semibold)

                        Spacer()

                        Label("09:00 AM", systemImage: "clock")
                            .foregroundStyle(.gray)
                    }

                    VStack(alignment: .leading, spacing: 12) {

                        HStack {
                            Circle()
                                .fill(.green)
                                .frame(width: 10)

                            Text("Warehouse A")
                        }

                        Rectangle()
                            .fill(.gray.opacity(0.4))
                            .frame(width: 1, height: 20)
                            .padding(.leading, 4)

                        HStack {
                            Circle()
                                .fill(.red)
                                .frame(width: 10)

                            Text("Distribution Center")
                        }
                    }

                    HStack {

                        Text("42 km")
                            .foregroundStyle(.gray)

                        Spacer()

                        Button("Navigate") {

                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 30))
            }
        }
    }
}
