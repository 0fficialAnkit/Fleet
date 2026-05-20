//
//  MaintenanceCalendarView.swift
//  Fleet
//
//  Created by Codex on 20/05/26.
//

import SwiftUI

struct MaintenanceCalendarView: View {
    @State private var selectedDate = "19"
    @State private var monthIndex = 4

    var body: some View {
        MaintenanceScreenContainer {
            MaintenanceSectionTitle(title: "Maintenance Calendar")

            HStack {
                monthArrow(systemName: "chevron.left", step: -1)
                Spacer()
                Text(MaintenanceSampleData.months[monthIndex])
                    .font(.system(size: 21, weight: .bold))
                Spacer()
                monthArrow(systemName: "chevron.right", step: 1)
            }

            TabView(selection: $monthIndex) {
                ForEach(Array(MaintenanceSampleData.months.enumerated()), id: \.offset) { index, _ in
                    MaintenancePanel(cornerRadius: 30) {
                        CalendarMonthCard(selectedDate: $selectedDate)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 24)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 452)

            VStack(alignment: .leading, spacing: 18) {
                MaintenanceThemeReader { theme in
                    Text(headerTitle)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(theme.primaryText)
                }

                if let service = selectedServices.first {
                    CalendarServiceCard(service: service)
                }
            }
        }
    }

    private var selectedServices: [MaintenanceCalendarService] {
        MaintenanceSampleData.calendarServices[selectedDate] ?? []
    }

    private var headerTitle: String {
        let count = selectedServices.count
        return "May \(selectedDate) — \(count) \(count == 1 ? "service" : "services")"
    }

    private func monthArrow(systemName: String, step: Int) -> some View {
        MaintenanceThemeReader { theme in
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    monthIndex = min(max(monthIndex + step, 0), MaintenanceSampleData.months.count - 1)
                }
            } label: {
                Circle()
                    .fill(theme.iconCircleFill)
                    .frame(width: 54, height: 54)
                    .overlay {
                        Image(systemName: systemName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(theme.primaryText)
                    }
            }
            .buttonStyle(.plain)
        }
    }
}

private struct CalendarMonthCard: View {
    @Binding var selectedDate: String

    var body: some View {
        MaintenanceThemeReader { theme in
            VStack(spacing: 20) {
                HStack {
                    ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                        Text(day)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.secondaryText)
                            .frame(maxWidth: .infinity)
                    }
                }

                VStack(spacing: 14) {
                    ForEach(MaintenanceSampleData.calendarDays, id: \.self) { row in
                        HStack {
                            ForEach(row, id: \.self) { value in
                                CalendarDayCell(
                                    value: value,
                                    selectedDate: selectedDate,
                                    marker: MaintenanceSampleData.calendarMarkers[value]
                                ) {
                                    if !value.isEmpty {
                                        selectedDate = value
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct CalendarDayCell: View {
    let value: String
    let selectedDate: String
    let marker: Color?
    let action: () -> Void

    var body: some View {
        MaintenanceThemeReader { theme in
            if value.isEmpty {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            } else {
                Button(action: action) {
                    VStack(spacing: 6) {
                        Text(value)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(selectedDate == value ? Color.white : theme.primaryText)
                            .frame(width: 54, height: 54)
                            .background {
                                if selectedDate == value {
                                    Circle()
                                        .fill(Color(red: 0.10, green: 0.49, blue: 1.0))
                                }
                            }

                        if let marker, selectedDate != value {
                            Circle()
                                .fill(marker)
                                .frame(width: 6, height: 6)
                        } else {
                            Color.clear
                                .frame(width: 6, height: 6)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct CalendarServiceCard: View {
    let service: MaintenanceCalendarService

    var body: some View {
        MaintenanceThemeReader { theme in
            MaintenancePanel(cornerRadius: 28) {
                HStack(spacing: 18) {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(service.tint.opacity(theme.isDark ? 0.16 : 0.12))
                        .frame(width: 72, height: 72)
                        .overlay {
                            Image(systemName: "wrench.and.screwdriver")
                                .font(.system(size: 29, weight: .medium))
                                .foregroundStyle(service.tint)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(service.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(theme.primaryText)

                        Text(service.vehicle)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(theme.secondaryText)
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.system(size: 17, weight: .medium))
                        Text(service.time)
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundStyle(service.tint)
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 26)
            }
        }
    }
}

#Preview("Maintenance Calendar") {
    MaintenanceCalendarView()
        .preferredColorScheme(.dark)
}
