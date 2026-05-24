import SwiftUI

struct EmployeeDetailView: View {
    let profile: Profile
    let viewModel: EmployeesViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingEditSheet = false
    
    var currentProfile: Profile {
        viewModel.profiles.first { $0.id == profile.id } ?? profile
    }
    
    var currentRoleName: String {
        viewModel.getRole(for: currentProfile)
    }
    
    var credentialsShareText: String {
        """
        Welcome to the Fleet App, \(currentProfile.fullName)!
        
        Your login credentials are:
        Email: \(currentProfile.email)
        Password: [Set during account creation]
        
        Please log in to access your portal.
        """
    }
    
    var body: some View {
        ZStack {
            themeModel.backgroundPrimary.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: themeModel.spacingLG) {
                    // Header Profile Section
                    VStack(spacing: themeModel.spacingSM) {
                        ZStack {
                            Circle()
                                .fill(viewModel.getColor(for: currentRoleName).opacity(0.15))
                                .frame(width: 110, height: 110)
                            
                            Image(systemName: viewModel.getIcon(for: currentRoleName))
                                .font(.system(size: 44))
                                .foregroundColor(viewModel.getColor(for: currentRoleName))
                        }
                        .padding(.bottom, 8)
                        
                        Text(currentProfile.fullName)
                            .font(themeModel.largeTitle(28))
                            .foregroundColor(themeModel.textPrimary)
                        
                        Text(currentRoleName)
                            .font(themeModel.bodyMedium(14))
                            .foregroundColor(viewModel.getColor(for: currentRoleName))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(viewModel.getColor(for: currentRoleName).opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .padding(.top, themeModel.spacingXL)
                    
                    // Information Cards
                    VStack(spacing: themeModel.spacingMD) {
                        InfoRowView(icon: "envelope.fill", title: "Email", value: currentProfile.email)
                        
                        if let phone = currentProfile.phone {
                            Divider().background(themeModel.divider)
                            InfoRowView(icon: "phone.fill", title: "Phone", value: phone)
                        }
                        
                        if currentProfile.role == "driver", let license = currentProfile.licenseNumber, !license.isEmpty {
                            Divider().background(themeModel.divider)
                            InfoRowView(icon: "lanyardcard.fill", title: "License", value: license)
                        }
                        
                        if let status = currentProfile.userStatus {
                            Divider().background(themeModel.divider)
                            InfoRowView(
                                icon: status == .active ? "checkmark.circle.fill" : "xmark.circle.fill",
                                title: "Status",
                                value: status.rawValue.capitalized,
                                valueColor: status == .active ? themeModel.success : themeModel.textSecondary
                            )
                        }
                        
                        if let date = currentProfile.createdAt {
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ShareLink(
                        item: credentialsShareText,
                        subject: Text("Fleet App Login Credentials"),
                        message: Text("Here are your login details:")
                    ) {
                        Label("Share Credentials", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: {
                        isShowingEditSheet = true
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: {
                        viewModel.deleteEmployee(currentProfile)
                        dismiss()
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(themeModel.textPrimary)
                        .padding(8)
                }
            }
        }
        .sheet(isPresented: $isShowingEditSheet) {
            EditEmployeeView(profile: currentProfile, viewModel: viewModel)
        }
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
            profile: Profile(id: UUID(), fullName: "Ravi Kumar", email: "ravi@fleet.in", role: "driver"),
            viewModel: EmployeesViewModel()
        )
        .preferredColorScheme(.dark)
    }
}
