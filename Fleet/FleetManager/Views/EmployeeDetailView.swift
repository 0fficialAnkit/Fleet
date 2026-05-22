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
                    ProfileHeader(
                        icon: viewModel.getIcon(for: roleName),
                        name: user.fullName,
                        role: roleName,
                        accentColor: viewModel.getColor(for: roleName)
                    )
                    .padding(.top, themeModel.spacingXL)
                    
                    // Information Cards
                    
                        VStack(spacing: 0) {
                            InfoRow(icon: "envelope.fill", label: "Email", value: user.email)
                            
                            if let phone = user.phone {
                                Divider().background(themeModel.divider)
                                InfoRow(icon: "phone.fill", label: "Phone", value: phone)
                            }
                            
                            if roleName.lowercased() == "driver", let license = user.licenseNumber, !license.isEmpty {
                                Divider().background(themeModel.divider)
                                InfoRow(icon: "licenseplate", label: "License", value: license)
                            }
                            
                            if let status = user.status {
                                Divider().background(themeModel.divider)
                                InfoRow(
                                    icon: status == .active ? "checkmark.circle.fill" : "xmark.circle.fill",
                                    label: "Status",
                                    value: status.rawValue.capitalized,
                                    valueColor: status == .active ? themeModel.success : themeModel.textSecondary
                                )
                            }
                            
                            if let date = user.createdAt {
                                Divider().background(themeModel.divider)
                                InfoRow(icon: "calendar", label: "Joined", value: date.formatted(date: .abbreviated, time: .omitted))
                            }
                        }
                        .padding(themeModel.spacingMD)
                        .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                        )
                        .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
                    .padding(.horizontal, themeModel.spacingMD)
                }
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        EmployeeDetailView(
            user: MockData.users.first(where: { $0.fullName == "Ravi Kumar" }) ?? MockData.users.first!,
            roleName: "Driver",
            viewModel: EmployeesViewModel()
        )
    }
}
