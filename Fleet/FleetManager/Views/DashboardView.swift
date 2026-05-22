import SwiftUI
import MapKit

struct DashboardView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        metricsSection
                        fleetHealthSection
                        liveLocationsSection
                        recentAlertsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.blue)
                        
                        Text("FleetOps")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                        
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                            .offset(x: 2, y: -2)
                    }
                }
            }
            .toolbarBackground(Color(.systemGroupedBackground), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    // MARK: - Metrics Section
    private var metricsSection: some View {
        VStack(spacing: 16) {
            // Total Fleet
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("TOTAL FLEET")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .kerning(1.0)
                    
                    HStack(alignment: .bottom, spacing: 6) {
                        Text("24")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .bold))
                            Text("+2")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.green)
                        .padding(.bottom, 6)
                    }
                }
                Spacer()
                VStack {
                    Image(systemName: "car")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                    Spacer()
                }
            }
            .padding(20)
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(16)
            
            // Split cards
            HStack(spacing: 16) {
                // Active Trips
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("ACTIVE TRIPS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)
                            .kerning(0.5)
                        Spacer()
                        Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                            .foregroundColor(.green)
                    }
                    Text("18")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.primary)
                }
                .padding(16)
                .background(Color.green.opacity(0.15))
                .cornerRadius(16)
                
                // Maintenance
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("MAINTENANCE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.orange)
                            .kerning(0.5)
                        Spacer()
                        Image(systemName: "wrench")
                            .foregroundColor(.orange)
                    }
                    Text("3")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.primary)
                }
                .padding(16)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(16)
            }
        }
    }
    
    // MARK: - Fleet Health
    private var fleetHealthSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fleet Health")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                // Uptime
                VStack(spacing: 8) {
                    HStack {
                        Text("System Uptime")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("98.5%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(.quaternarySystemFill))
                                .frame(height: 8)
                            Capsule()
                                .fill(Color.blue)
                                .frame(width: geo.size.width * 0.985, height: 8)
                        }
                    }
                    .frame(height: 8)
                }
                
                // Fuel Target
                VStack(spacing: 8) {
                    HStack {
                        Text("Fuel Efficiency Target")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("82%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(.quaternarySystemFill))
                                .frame(height: 8)
                            Capsule()
                                .fill(Color.orange)
                                .frame(width: geo.size.width * 0.82, height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Live Locations
    private var liveLocationsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Live Locations")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Button(action: {}) {
                    Text("VIEW MAP")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.blue)
                        .kerning(0.5)
                }
            }
            .padding(16)
            
            Map(initialPosition: .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 41.8781, longitude: -87.6298), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))))
                .disabled(true)
                .frame(height: 140)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Recent Alerts
    private var recentAlertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Alerts")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Button(action: {}) {
                    Text("SEE ALL")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .kerning(0.5)
                }
            }
            
            VStack(spacing: 16) {
                alertRow(icon: "exclamationmark.triangle", iconColor: .orange, title: "Vehicle #402 reported is...", desc: "Engine temperature alert.\nDriver notified.", time: "10m ago")
                Divider()
                alertRow(icon: "checkmark.circle", iconColor: .green, title: "Delivery #8921 Complet...", desc: "Route 4 finished on schedule.", time: "45m ago")
                Divider()
                alertRow(icon: "fuelpump", iconColor: .blue, title: "Fuel Card Used: V-#112", desc: "Shell Station, Downtown Branch.", time: "2h ago")
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
    }
    
    private func alertRow(icon: String, iconColor: Color, title: String, desc: String, time: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 16))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(time)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    DashboardView()
}
