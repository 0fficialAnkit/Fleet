import SwiftUI

struct EmployeeDetailView: View {
    let user: User
    let roleName: String
    let viewModel: EmployeesViewModel
    
    var body: some View {
        ZStack {
            themeModel.backgroundPrimary.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: themeModel.spacingLG) {
                    // Header Profile Section
                    VStack(spacing: themeModel.spacingSM) {
                        ZStack {
                            Circle()
                                .fill(viewModel.getColor(for: roleName).opacity(0.15))
                                .frame(width: 110, height: 110)
                            
                            Image(systemName: viewModel.getIcon(for: roleName))
                                .font(.system(size: 44))
                                .foregroundColor(viewModel.getColor(for: roleName))
                        }
                        .padding(.bottom, 8)
                        
                        Text(user.fullName)
                            .font(themeModel.largeTitle(28))
                            .foregroundColor(themeModel.textPrimary)
                        
                        Text(roleName)
                            .font(themeModel.bodyMedium(14))
                            .foregroundColor(viewModel.getColor(for: roleName))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(viewModel.getColor(for: roleName).opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .padding(.top, themeModel.spacingXL)
                    
                    // Information Cards
                    VStack(spacing: themeModel.spacingMD) {
                        InfoRowView(icon: "envelope.fill", title: "Email", value: user.email)
                        
                        if let phone = user.phone {
                            Divider().background(themeModel.divider)
                            InfoRowView(icon: "phone.fill", title: "Phone", value: phone)
                        }
                        
                        if roleName.lowercased() == "driver", let license = user.licenseNumber, !license.isEmpty {
                            Divider().background(themeModel.divider)
                            InfoRowView(icon: "lanyardcard.fill", title: "License", value: license)
                        }
                        
                        if let status = user.status {
                            Divider().background(themeModel.divider)
                            InfoRowView(
                                icon: status == .active ? "checkmark.circle.fill" : "xmark.circle.fill",
                                title: "Status",
                                value: status.rawValue.capitalized,
                                valueColor: status == .active ? themeModel.success : themeModel.textSecondary
                            )
                        }
                        
                        if let date = user.createdAt {
                            Divider().background(themeModel.divider)
                            InfoRowView(icon: "calendar", title: "Joined", value: date.formatted(date: .abbreviated, time: .omitted))
                        }
                    }
                    .padding(themeModel.spacingMD)
                    .background(themeModel.backgroundElevated)
                    .cornerRadius(themeModel.radiusLG)
                    .padding(.horizontal, themeModel.spacingMD)
                }
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(themeModel.backgroundPrimary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct InfoRowView: View {
    let icon: String
    let title: String
    let value: String
    var valueColor: Color = themeModel.textPrimary
    
    var body: some View {
        HStack(spacing: themeModel.spacingMD) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(themeModel.textTertiary)
                .frame(width: 24)
            
            Text(title)
                .font(themeModel.bodyMedium(16))
                .foregroundColor(themeModel.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(themeModel.body(16))
                .foregroundColor(valueColor)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        EmployeeDetailView(
            user: MockData.users.first(where: { $0.fullName == "Ravi Kumar" }) ?? MockData.users.first!,
            roleName: "Driver",
            viewModel: EmployeesViewModel()
        )
        .preferredColorScheme(.dark)
    }
}
