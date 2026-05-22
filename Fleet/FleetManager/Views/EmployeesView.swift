import SwiftUI

struct EmployeesView: View {
    var viewModel: EmployeesViewModel
    let roleFilter: String
    
    var filteredEmployees: [User] {
        viewModel.employees.filter { user in
            let role = viewModel.getRole(for: user)
            return role?.roleName.lowercased() == roleFilter.lowercased()
        }
    }
    
    var body: some View {
        Group {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: themeModel.spacingMD) {
                        ForEach(filteredEmployees) { user in
                            let role = viewModel.getRole(for: user)
                            let roleName = role?.roleName ?? "Unknown Role"
                            
                            NavigationLink(destination: EmployeeDetailView(user: user, viewModel: viewModel)) {
                                EmployeeRowView(
                                    user: user,
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
    let user: User
    let roleName: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: themeModel.spacingMD) {
            VStack(alignment: .leading, spacing: 4) {
                Text(user.fullName)
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
        .padding(themeModel.spacingMD)
        .background(themeModel.backgroundElevated)
        .cornerRadius(themeModel.radiusLG)
    }
}

#Preview {
    NavigationStack {
        EmployeesView(viewModel: EmployeesViewModel(), roleFilter: "driver")
    }
}
