import SwiftUI

struct EmployeesView: View {
    var viewModel: EmployeesViewModel
    let roleFilter: String
    
    var filteredEmployees: [Profile] {
        viewModel.employees.filter { profile in
            profile.role.lowercased() == roleFilter.lowercased()
        }
    }
    
    var body: some View {
        Group {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: themeModel.spacingMD) {
                        ForEach(filteredEmployees) { profile in
                            let roleName = viewModel.getRole(for: profile)
                            
                            NavigationLink(destination: EmployeeDetailView(profile: profile, viewModel: viewModel)) {
                                EmployeeRowView(
                                    profile: profile,
                                    roleName: roleName,
                                    icon: viewModel.getIcon(for: roleName),
                                    iconColor: viewModel.getColor(for: roleName)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, themeModel.spacingMD)
                    .padding(.horizontal, themeModel.spacingMD)
                }
            }
            }
        }
    }


struct EmployeeRowView: View {
    let profile: Profile
    let roleName: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: themeModel.spacingMD) {
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.fullName)
                    .font(themeModel.headline(18))
                    .foregroundColor(themeModel.textPrimary)
                
                Text(roleName)
                    .font(themeModel.caption(14))
                    .foregroundColor(themeModel.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .padding(10)
                .background(iconColor.opacity(0.15))
                .clipShape(Circle())
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(themeModel.textTertiary)
        }
//        .padding(themeModel.spacingMD)
//        .background(themeModel.backgroundElevated)
//        .cornerRadius(themeModel.radiusLG)
        .padding(themeModel.spacingMD)
        .background(
            themeModel.surfaceTertiary.opacity(0.35)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: themeModel.radiusLG,
                style: .continuous
            )
        )
        .glassEffect(
            in: RoundedRectangle(
                cornerRadius: themeModel.radiusLG,
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: themeModel.radiusLG,
                style: .continuous
            )
            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
    }
}

#Preview {
    NavigationStack {
        EmployeesView(viewModel: EmployeesViewModel(), roleFilter: "driver")
    }
}
