import SwiftUI

struct ActiveTripChecklist: Identifiable {
    let id: UUID
    let type: InspectionType
}

struct DriverTripsView: View {

    @State private var viewModel = DriverTripsViewModel()
    @State private var activeChecklist: ActiveTripChecklist? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(viewModel.sortedTrips) { trip in
                        DriverTripCardView(trip: trip, onStart: {
                            activeChecklist = ActiveTripChecklist(id: trip.id, type: .preTrip)
                        }, onEnd: {
                            activeChecklist = ActiveTripChecklist(id: trip.id, type: .postTrip)
                        })
                    }
                }
                .padding()
            }
            .background(themeModel.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Assigned Routes")
            .sheet(item: $activeChecklist) { checklist in
                DriverChecklistView(checklistType: checklist.type) {
                    if checklist.type == .preTrip {
                        viewModel.startTrip(id: checklist.id)
                    } else {
                        viewModel.endTrip(id: checklist.id)
                    }
                }
            }
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
        case .active: return themeModel.driverPrimary
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
                    
                    StatusBadge(text: statusText, color: statusColor)
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
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Start Trip")
                            }
                            .font(themeModel.bodyMedium())
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(themeModel.driverPrimary)
                    } else if trip.status == .active {
                        Button(action: onEnd) {
                            HStack {
                                Image(systemName: "stop.fill")
                                Text("End Trip")
                            }
                            .font(themeModel.bodyMedium())
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(themeModel.success)
                    }
                }
            }
            .padding(themeModel.spacingMD)
            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
    }
}

#Preview {
    DriverTripsView()
}
