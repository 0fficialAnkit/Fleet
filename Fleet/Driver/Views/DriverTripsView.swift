import SwiftUI

struct DriverTripsView: View {

    @State private var viewModel = DriverTripsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(viewModel.sortedTrips) { trip in
                        DriverTripCardView(trip: trip, onStart: {
                            viewModel.startTrip(id: trip.id)
                        }, onEnd: {
                            viewModel.endTrip(id: trip.id)
                        })
                    }
                }
                .padding()
            }
            .background(themeModel.backgroundPrimary.ignoresSafeArea())
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
        case .scheduled: return themeModel.warning
        case .active: return themeModel.info
        case .completed: return themeModel.success
        case .cancelled: return themeModel.danger
        case .none: return themeModel.textDisabled
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
        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
            HStack {
                Text("Route #\(trip.id.uuidString.prefix(4))")
                    .font(themeModel.headline())
                    .foregroundStyle(themeModel.textPrimary)
                
                Spacer()
                
                Text(statusText)
                    .font(themeModel.small())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15))
                    .foregroundStyle(statusColor)
                    .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusXS))
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(themeModel.success)
                    Text("Start: Warehouse")
                        .font(themeModel.bodyMedium())
                        .foregroundStyle(themeModel.textSecondary)
                }
                
                Rectangle()
                    .fill(themeModel.divider)
                    .frame(width: 2, height: 16)
                    .padding(.leading, 3)
                
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(themeModel.danger)
                    Text("Destination: Drop-off Zone")
                        .font(themeModel.bodyMedium())
                        .foregroundStyle(themeModel.textPrimary)
                }
            }
            .padding(.vertical, 4)

            HStack {
                Label(trip.startTime?.formatted(date: .omitted, time: .shortened) ?? "N/A", systemImage: "clock")
                    .font(themeModel.caption())
                    .foregroundStyle(themeModel.textTertiary)
                
                Spacer()
                
                if trip.status == .scheduled {
                    Button(action: onStart) {
                        Text("Start Trip")
                            .font(themeModel.bodyMedium())
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(themeModel.info)
                } else if trip.status == .active {
                    Button(action: onEnd) {
                        Text("End Trip")
                            .font(themeModel.bodyMedium())
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(themeModel.success)
                }
            }
        }
        .padding(themeModel.spacingMD)
        .background(themeModel.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusLG))
        .overlay(
            RoundedRectangle(cornerRadius: themeModel.radiusLG)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    DriverTripsView()
}
