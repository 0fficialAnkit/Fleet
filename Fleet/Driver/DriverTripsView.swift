import SwiftUI

struct DriverTripsView: View {

    @StateObject private var dataStore = DataStore.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(dataStore.trips.sorted(by: { ($0.startTime ?? Date()) < ($1.startTime ?? Date()) })) { trip in
                        DriverTripCardView(trip: trip, onStart: {
                            if let index = dataStore.trips.firstIndex(where: { $0.id == trip.id }) {
                                dataStore.trips[index].status = .active
                                dataStore.trips[index].startTime = Date() // Record start time
                            }
                        }, onEnd: {
                            if let index = dataStore.trips.firstIndex(where: { $0.id == trip.id }) {
                                dataStore.trips[index].status = .completed
                                dataStore.trips[index].endTime = Date() // Record end time
                            }
                        })
                    }
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("Assigned Routes")
        }
    }
}

struct DriverTripCardView: View {
    let trip: Trip
    let onStart: () -> Void
    let onEnd: () -> Void

    var statusColor: Color {
        switch trip.status {
        case .scheduled: return .orange
        case .active: return .blue
        case .completed: return .green
        case .cancelled: return .red
        case .none: return .gray
        }
    }

    var statusText: String {
        switch trip.status {
        case .scheduled: return "Pending"
        case .active: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .none: return "Unknown"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Route #\(trip.id.uuidString.prefix(4))")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(statusText)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.green)
                    Text("Start: Warehouse")
                        .foregroundColor(.secondary)
                }
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 2, height: 16)
                    .padding(.leading, 3)
                
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                    Text("Destination: Drop-off Zone")
                        .foregroundColor(.primary)
                }
            }
            .padding(.vertical, 4)

            HStack {
                Label(trip.startTime?.formatted(date: .omitted, time: .shortened) ?? "N/A", systemImage: "clock")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                if trip.status == .scheduled {
                    Button(action: onStart) {
                        Text("Start Trip")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                } else if trip.status == .active {
                    Button(action: onEnd) {
                        Text("End Trip")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    DriverTripsView()
}
