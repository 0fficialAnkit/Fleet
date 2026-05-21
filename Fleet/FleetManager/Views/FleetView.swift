import SwiftUI

struct FleetView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: themeModel.spacingMD) {
                        NavigationLink(destination: VehiclesView()) {
                            FleetOptionCard(title: "Vehicles", icon: "car.fill", color: themeModel.info)
                        }
                        .buttonStyle(.plain)
                        
                        NavigationLink(destination: EmployeesView()) {
                            FleetOptionCard(title: "Employees", icon: "person.3.fill", color: themeModel.analyticsPurple)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, themeModel.spacingMD)
                    .padding(.horizontal, themeModel.spacingMD)
                }
            }
            .navigationTitle("Fleet")
        }
    }
}

struct FleetOptionCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: themeModel.spacingMD) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(themeModel.headline(18))
                .foregroundColor(themeModel.textPrimary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(themeModel.textTertiary)
        }
        .padding(themeModel.spacingMD)
        .background(themeModel.backgroundElevated)
        .cornerRadius(themeModel.radiusLG)
    }
}

#Preview {
    FleetView()
}
