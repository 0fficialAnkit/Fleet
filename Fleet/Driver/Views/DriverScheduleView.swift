import SwiftUI

struct DriverScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: DriverTripsViewModel
    
    @State private var selectedDate: Date = Date()
    @State private var currentWeekOffset: Int = 0 // to allow navigating weeks
    
    private let calendar = Calendar.current
    
    // MARK: - Weekly Date Generator
    private var daysOfCurrentWeek: [Date] {
        let today = calendar.startOfDay(for: Date())
        guard let startOfWeek = calendar.date(byAdding: .day, value: currentWeekOffset * 7, to: today) else {
            return []
        }
        
        // Find Sunday (or Monday depending on locale, let's use Sunday as start)
        let weekday = calendar.component(.weekday, from: startOfWeek)
        let daysToSubtract = weekday - 1
        
        guard let sunday = calendar.date(byAdding: .day, value: -daysToSubtract, to: startOfWeek) else {
            return []
        }
        
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: sunday)
        }
    }
    
    // MARK: - Filter Trips for Selected Date
    private var tripsForSelectedDate: [Trip] {
        viewModel.trips.filter { trip in
            guard let startTime = trip.startTime else { return false }
            return calendar.isDate(startTime, inSameDayAs: selectedDate)
        }
    }
    
    // Check if a date has any trips
    private func hasTrips(on date: Date) -> Bool {
        viewModel.trips.contains { trip in
            guard let startTime = trip.startTime else { return false }
            return calendar.isDate(startTime, inSameDayAs: date)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: Week Selector & Header
                VStack(spacing: 16) {
                    // Month name and navigation
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(selectedDate.formatted(.dateTime.year()))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.secondary)
                            
                            Text(selectedDate.formatted(.dateTime.month(.wide)))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.primary)
                        }
                        
                        Spacer()
                        
                        // Week Navigation Buttons
                        HStack(spacing: 8) {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    currentWeekOffset -= 1
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.subheadline.weight(.semibold))
                                    .padding(8)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .clipShape(Circle())
                            }
                            
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    currentWeekOffset = 0
                                    selectedDate = Date()
                                }
                            } label: {
                                Text("Today")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .clipShape(Capsule())
                            }
                            
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    currentWeekOffset += 1
                                }
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.subheadline.weight(.semibold))
                                    .padding(8)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Horizontal Week Strip
                    HStack(spacing: 0) {
                        ForEach(daysOfCurrentWeek, id: \.self) { day in
                            let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
                            let isToday = calendar.isDateInToday(day)
                            let hasScheduledTrips = hasTrips(on: day)
                            
                            VStack(spacing: 8) {
                                Text(day.formatted(.dateTime.weekday(.narrow)))
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(isSelected ? .white : Color.secondary)
                                
                                Text(day.formatted(.dateTime.day()))
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(isSelected ? .white : (isToday ? Color.green : Color.primary))
                                    .frame(width: 38, height: 38)
                                    .background(
                                        ZStack {
                                            if isSelected {
                                                Circle()
                                                    .fill(Color.green)
                                                    .matchedGeometryEffect(id: "selectedDayHighlight", in: namespace)
                                            } else if isToday {
                                                Circle()
                                                    .stroke(Color.green.opacity(0.5), lineWidth: 1.5)
                                            }
                                        }
                                    )
                                
                                // Indicator for trips
                                Circle()
                                    .fill(isSelected ? .white : Color.green)
                                    .frame(width: 5, height: 5)
                                    .opacity(hasScheduledTrips ? 1 : 0)
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedDate = day
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 12)
                }
                .background(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)
                
                // MARK: Trips List for selected day
                ZStack {
                    Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                    
                    if tripsForSelectedDate.isEmpty {
                        ContentUnavailableView {
                            Label("No Trips Assigned", systemImage: "calendar.badge.clock")
                        } description: {
                            Text("Enjoy your day off! No transport routes are scheduled for \(selectedDate.formatted(date: .long, time: .omitted)).")
                        }
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 16) {
                                ForEach(tripsForSelectedDate) { trip in
                                    ScheduleTripRow(
                                        trip: trip,
                                        route: viewModel.routeForTrip(trip),
                                        vehicle: viewModel.vehicleForTrip(trip)
                                    )
                                }
                            }
                            .padding(16)
                        }
                        .refreshable { await viewModel.loadData() }
                    }
                }
            }
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(Color.green)
                }
            }
        }
    }
    
    @Namespace private var namespace
}

// MARK: - Schedule Trip Row

struct ScheduleTripRow: View {
    let trip: Trip
    let route: Route?
    let vehicle: Vehicle?
    
    var statusColor: Color {
        switch trip.status {
        case .scheduled: return Color.blue
        case .active:    return Color.green
        case .completed: return Color.gray
        case .cancelled: return Color.red
        case .none:      return Color.secondary
        }
    }
    
    var statusText: String {
        switch trip.status {
        case .scheduled: return "Scheduled"
        case .active:    return "Active"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .none:      return "Unknown"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Time and Status
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                    
                    if let startTime = trip.startTime {
                        Text(startTime.formatted(date: .omitted, time: .shortened))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.primary)
                    } else {
                        Text("Anytime")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.primary)
                    }
                    
                    if let endTime = trip.endTime {
                        Text("- \(endTime.formatted(date: .omitted, time: .shortened))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                    }
                }
                
                Spacer()
                
                StatusBadge(text: statusText, color: statusColor)
            }
            
            Divider()
            
            // Route locations
            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    
                    Rectangle()
                        .fill(Color(UIColor.separator))
                        .frame(width: 1.5, height: 22)
                    
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.red)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PICKUP")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.secondary)
                        Text(route?.startLocation ?? "Origin Location")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.primary)
                            .lineLimit(1)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DELIVERY")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.secondary)
                        Text(route?.endLocation ?? "Destination Location")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.primary)
                            .lineLimit(1)
                    }
                }
            }
            
            Divider()
            
            // Vehicle & Order Info
            HStack(spacing: 16) {
                if let vehicle {
                    Label("\(vehicle.make ?? "") \(vehicle.model ?? "")", systemImage: "truck.box.fill")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if let orderType = trip.orderType {
                    Label(orderType.displayName, systemImage: "shippingbox.fill")
                        .font(.caption)
                        .foregroundStyle(Color.blue)
                }
                
                if let distance = trip.distance, distance > 0 {
                    Text(String(format: "%.0f km", distance))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 3)
    }
}
