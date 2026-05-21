import SwiftUI
import MapKit

struct DashboardView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.97, green: 0.97, blue: 0.99)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        headerView
                        
                        // Metrics Grid
                        metricsGrid
                        
                        // Active Trips
                        activeTripsSection
                        
                        // Quick Actions
                        quickActionsSection
                        
                        // Recent Alerts
                        recentAlertsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(Color(red: 0.05, green: 0.15, blue: 0.35))
                .clipShape(Circle())
            
            Text("FleetControl")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(red: 0.05, green: 0.15, blue: 0.45))
            
            Spacer()
            
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(red: 0.05, green: 0.15, blue: 0.45))
                
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .offset(x: 2, y: -2)
            }
        }
        .padding(.top, 16)
    }
    
    // MARK: - Metrics Grid
    private var metricsGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Card 1
                metricCard(title: "TOTAL", icon: "box.truck", value: "124", subTitle: "FLEET SIZE", subColor: .gray, iconColor: .blue)
                
                // Card 2
                metricCard(title: "ACTIVE", icon: "bolt.fill", value: "98", subTitle: "79% UTILIZATION", subColor: .green, iconColor: .green, showDot: true)
            }
            HStack(spacing: 12) {
                // Card 3
                metricCard(title: "SERVICE", icon: "wrench", value: "12", subTitle: "MAINTENANCE", subColor: .orange, iconColor: .orange)
                
                // Card 4
                metricCard(title: "ALERTS", icon: "exclamationmark.triangle", value: "4", subTitle: "URGENT ACTION", subColor: .red, iconColor: .red, isAlert: true)
            }
        }
    }
    
    private func metricCard(title: String, icon: String, value: String, subTitle: String, subColor: Color, iconColor: Color, showDot: Bool = false, isAlert: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isAlert ? .red : .gray)
                    .kerning(1.0)
                Spacer()
                if showDot {
                    Circle().fill(Color.green).frame(width: 6, height: 6)
                }
                Image(systemName: icon)
                    .foregroundColor(iconColor)
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(isAlert ? .red : .primary)
            
            Text(subTitle)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(subColor)
                .kerning(0.5)
        }
        .padding(16)
        .background(isAlert ? Color.red.opacity(0.15) : Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isAlert ? Color.red.opacity(0.3) : Color(red: 0.9, green: 0.9, blue: 0.95), lineWidth: 1)
        )
    }
    
    // MARK: - Active Trips
    private var activeTripsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Trips")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.25))
                Spacer()
                Button(action: {}) {
                    Text("View All")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.6))
                }
            }
            
            VStack(spacing: 0) {
                // Map background
                ZStack(alignment: .bottomLeading) {
                    Map(initialPosition: .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795), span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30))))
                        .disabled(true)
                        .frame(height: 140)
                        .overlay(Color(red: 0.1, green: 0.2, blue: 0.3).opacity(0.4))
                        .clipped()
                    
                    Text("((•)) LIVE TRACKING")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.05, green: 0.2, blue: 0.6))
                        .cornerRadius(12)
                        .padding(12)
                }
                
                VStack(spacing: 16) {
                    tripProgressBar(id: "TRP-902", route: "Chicago → Detroit", percentage: 85)
                    tripProgressBar(id: "TRP-441", route: "Dallas → Austin", percentage: 42)
                    tripProgressBar(id: "TRP-112", route: "Seattle → Portland", percentage: 12)
                }
                .padding(16)
                .background(Color.white)
            }
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(red: 0.9, green: 0.9, blue: 0.95), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 5, y: 2)
        }
    }
    
    private func tripProgressBar(id: String, route: String, percentage: Double) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(id) (\(route))")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black)
                Spacer()
                Text("\(Int(percentage))%")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(red: 0.9, green: 0.9, blue: 0.95))
                        .frame(height: 6)
                    Capsule()
                        .fill(Color(red: 0.05, green: 0.15, blue: 0.55))
                        .frame(width: geometry.size.width * (percentage / 100), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.25))
            
            VStack(spacing: 10) {
                quickActionButton(icon: "plus.circle", title: "Add Vehicle", isPrimary: true)
                quickActionButton(icon: "person.badge.plus", title: "Assign Driver", isPrimary: false)
                quickActionButton(icon: "calendar", title: "Schedule Service", isPrimary: false)
            }
        }
    }
    
    private func quickActionButton(icon: String, title: String, isPrimary: Bool) -> some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .foregroundColor(isPrimary ? .white : Color(red: 0.1, green: 0.2, blue: 0.3))
            .background(isPrimary ? Color(red: 0.05, green: 0.2, blue: 0.5) : Color(red: 0.88, green: 0.92, blue: 0.98))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isPrimary ? Color.clear : Color(red: 0.8, green: 0.85, blue: 0.95), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Recent Alerts
    private var recentAlertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Alerts")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.25))
                Spacer()
                Text("4 NEW")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .cornerRadius(8)
            }
            
            VStack(spacing: 10) {
                alertItem(icon: "exclamationmark.circle", iconColor: .red, title: "Vehicle #42: Engine Overheating", desc: "Critical temperature reached. Shutdown recommended.", time: "2 MINS AGO", isCritical: true)
                alertItem(icon: "point.topleft.down.curvedto.point.bottomright.up", iconColor: .orange, title: "Driver John D.: Route Deviation", desc: "Unplanned stop at unauthorized location.", time: "14 MINS AGO", isCritical: false)
                alertItem(icon: "bell", iconColor: .blue, title: "Shift Start: Night Fleet", desc: "12 drivers logged in successfully.", time: "1 HOUR AGO", isCritical: false)
            }
        }
    }
    
    private func alertItem(icon: String, iconColor: Color, title: String, desc: String, time: String, isCritical: Bool) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(iconColor)
                .frame(width: 4)
            
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
                    .padding(.top, 2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                    Text(desc)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    Text(time)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                        .padding(.top, 2)
                }
                Spacer()
            }
            .padding(16)
            .background(isCritical ? Color.red.opacity(0.1) : Color(red: 0.97, green: 0.98, blue: 1.0))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    DashboardView()
}
