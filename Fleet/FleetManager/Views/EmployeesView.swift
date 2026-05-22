import SwiftUI

struct EmployeesView: View {
    @State private var viewModel = EmployeesViewModel()
    @State private var isShowingAddEmployee = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: themeModel.spacingMD) {
                        ForEach(viewModel.employees) { user in
                            let role = viewModel.getRole(for: user)
                            let roleName = role?.roleName ?? "Unknown Role"
                            
                            NavigationLink(destination: EmployeeDetailView(user: user, roleName: roleName, viewModel: viewModel)) {
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
            .navigationTitle("Employees")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        isShowingAddEmployee = true
                    }) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(themeModel.textPrimary)
                            .frame(width: 38, height: 38)
                            .glassEffect(in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $isShowingAddEmployee) {
                AddEmployeeView(viewModel: viewModel)
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
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
                    .frame(width: 44, height: 44)
                    .background(iconColor.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(user.fullName)
                        .font(themeModel.headline(18))
                        .foregroundColor(themeModel.textPrimary)
                    
                    Text(roleName)
                        .font(themeModel.caption(14))
                        .foregroundColor(themeModel.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeModel.textTertiary)
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
    EmployeesView()
}
