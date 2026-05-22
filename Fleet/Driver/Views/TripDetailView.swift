import SwiftUI

struct TripDetailView: View {

    let trip: Trip
    let onStart: (UUID) -> Void
    let onEnd: (UUID) -> Void

    // Local status so UI reacts immediately after start/end
    @State private var currentStatus: TripStatus?
    @State private var showingChecklist: InspectionType? = nil

    init(trip: Trip, onStart: @escaping (UUID) -> Void, onEnd: @escaping (UUID) -> Void) {
        self.trip = trip
        self.onStart = onStart
        self.onEnd = onEnd
        self._currentStatus = State(initialValue: trip.status)
    }

    // MARK: - Computed helpers

    var statusColor: Color {
        switch currentStatus {
        case .scheduled: return themeModel.warning
        case .active:    return themeModel.driverPrimary
        case .completed: return themeModel.success
        case .cancelled: return themeModel.danger
        default:         return themeModel.textDisabled
        }
    }

    var statusText: String {
        switch currentStatus {
        case .scheduled: return "Pending"
        case .active:    return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        default:         return "Unknown"
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {

                // ── Header ─────────────────────────────────────────
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Route #\(trip.id.uuidString.prefix(6).uppercased())")
                            .font(themeModel.title())
                            .foregroundStyle(themeModel.textPrimary)
                        StatusBadge(text: statusText, color: statusColor)
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(themeModel.driverPrimary.opacity(0.12))
                            .frame(width: 56, height: 56)
                        Image(systemName: "truck.box.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(themeModel.driverPrimary)
                    }
                }

                Divider()
                    .overlay(themeModel.divider)

                // ── Date & Time ────────────────────────────────────
                sectionTitle("Schedule")

                HStack(spacing: 12) {
                    infoTile(
                        icon: "calendar",
                        label: "Date",
                        value: trip.startTime?.formatted(date: .abbreviated, time: .omitted) ?? "Today",
                        color: themeModel.analyticsPurple
                    )
                    infoTile(
                        icon: "clock.fill",
                        label: "Start Time",
                        value: trip.startTime?.formatted(date: .omitted, time: .shortened) ?? "09:00 AM",
                        color: themeModel.driverPrimary
                    )
                    infoTile(
                        icon: "clock.badge.checkmark.fill",
                        label: "Est. End",
                        value: trip.endTime?.formatted(date: .omitted, time: .shortened) ?? "N/A",
                        color: themeModel.success
                    )
                }

                // ── Route ──────────────────────────────────────────
                sectionTitle("Route Details")

                VStack(alignment: .leading, spacing: 0) {
                    // Origin
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(themeModel.success.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: "circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(themeModel.success)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Pickup / Origin")
                                .font(themeModel.caption())
                                .foregroundStyle(themeModel.textSecondary)
                            Text("Warehouse A, Sector 12")
                                .font(themeModel.bodyMedium())
                                .foregroundStyle(themeModel.textPrimary)
                        }
                        Spacer()
                    }

                    // Connector line
                    Rectangle()
                        .fill(themeModel.divider)
                        .frame(width: 2, height: 32)
                        .padding(.leading, 19)

                    // Destination
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(themeModel.danger.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(themeModel.danger)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Drop-off / Destination")
                                .font(themeModel.caption())
                                .foregroundStyle(themeModel.textSecondary)
                            Text("Distribution Center, Zone B")
                                .font(themeModel.bodyMedium())
                                .foregroundStyle(themeModel.textPrimary)
                        }
                        Spacer()
                    }
                }
                .padding(themeModel.spacingMD)
                .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
                .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)

                // ── Distance Info ──────────────────────────────────
                HStack(spacing: 12) {
                    infoTile(
                        icon: "road.lanes",
                        label: "Distance",
                        value: trip.distance != nil ? String(format: "%.1f km", trip.distance!) : "42 km",
                        color: themeModel.warning
                    )
                    infoTile(
                        icon: "timer",
                        label: "Est. Duration",
                        value: "~38 min",
                        color: themeModel.analyticsPurple
                    )
                }

                // ── Map Placeholder ────────────────────────────────
                sectionTitle("Route Map")

                ZStack {
                    RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                        .fill(themeModel.driverPrimary.opacity(0.07))
                        .frame(height: 200)

                    VStack(spacing: 10) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(themeModel.driverPrimary.opacity(0.45))
                        Text("Map View")
                            .font(themeModel.bodyMedium())
                            .foregroundStyle(themeModel.textSecondary)
                        Text("Warehouse A  →  Distribution Center, Zone B")
                            .font(themeModel.caption())
                            .foregroundStyle(themeModel.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                        .stroke(themeModel.driverPrimary.opacity(0.2), lineWidth: 1)
                )

                // ── Action Buttons ─────────────────────────────────
                actionSection
            }
            .padding()
        }
        .background(themeModel.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Trip Details")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $showingChecklist) { type in
            DriverChecklistView(checklistType: type) {
                if type == .preTrip {
                    onStart(trip.id)
                    withAnimation { currentStatus = .active }
                } else {
                    onEnd(trip.id)
                    withAnimation { currentStatus = .completed }
                }
                showingChecklist = nil
            }
        }
    }

    // MARK: - Action Section

    @ViewBuilder
    var actionSection: some View {
        switch currentStatus {
        case .scheduled:
            Button {
                showingChecklist = .preTrip
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                    Text("Start Trip")
                        .font(themeModel.headline())
                }
                .frame(maxWidth: .infinity)
                .padding(themeModel.spacingMD)
                .background(themeModel.driverPrimary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusSM))
            }
            .shadow(color: themeModel.driverPrimary.opacity(0.35), radius: 10, y: 4)

        case .active:
            VStack(spacing: 12) {
                // In-progress banner
                HStack(spacing: 10) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(themeModel.driverPrimary)
                    Text("Trip is currently in progress")
                        .font(themeModel.bodyMedium())
                        .foregroundStyle(themeModel.driverPrimary)
                    Spacer()
                }
                .padding(themeModel.spacingMD)
                .background(themeModel.driverPrimary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusSM))

                // End Trip button
                Button {
                    showingChecklist = .postTrip
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "stop.fill")
                        Text("End Trip")
                            .font(themeModel.headline())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(themeModel.spacingMD)
                    .background(themeModel.danger)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusSM))
                }
                .shadow(color: themeModel.danger.opacity(0.35), radius: 10, y: 4)
            }

        case .completed:
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(themeModel.success)
                Text("Trip completed successfully")
                    .font(themeModel.bodyMedium())
                    .foregroundStyle(themeModel.success)
                Spacer()
            }
            .padding(themeModel.spacingMD)
            .background(themeModel.success.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusSM))

        default:
            EmptyView()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(themeModel.headline())
            .foregroundStyle(themeModel.textPrimary)
    }

    @ViewBuilder
    func infoTile(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            Text(label)
                .font(themeModel.caption())
                .foregroundStyle(themeModel.textSecondary)
            Text(value)
                .font(themeModel.bodyMedium())
                .foregroundStyle(themeModel.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(themeModel.spacingMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        TripDetailView(trip: MockData.trips[0], onStart: { _ in }, onEnd: { _ in })
    }
}
