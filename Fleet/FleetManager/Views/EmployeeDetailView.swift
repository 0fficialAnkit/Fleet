import SwiftUI

struct EmployeeDetailView: View {
    let user: User
    let viewModel: EmployeesViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingEditSheet = false
    
    var currentUser: User {
        viewModel.users.first { $0.id == user.id } ?? user
    }
    
    var currentRoleName: String {
        viewModel.getRole(for: currentUser)?.roleName ?? "Unknown Role"
    }
    
    var credentialsShareText: String {
        let pass = currentUser.passwordHash == "$2b$12$dummy" ? "[Ask Fleet Manager for Password]" : currentUser.passwordHash
        return """
        Welcome to the Fleet App, \(currentUser.fullName)!
        
        Your login credentials are:
        Email: \(currentUser.email)
        Password: \(pass)
        
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
                        
                        Text(currentUser.fullName)
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
                        InfoRowView(icon: "envelope.fill", title: "Email", value: currentUser.email)
                        
                        if let phone = currentUser.phone {
                            Divider().background(themeModel.divider)
                            InfoRowView(icon: "phone.fill", title: "Phone", value: phone)
                        }
                        
                        if currentRoleName.lowercased() == "driver", let license = currentUser.licenseNumber, !license.isEmpty {
                            Divider().background(themeModel.divider)
                            InfoRowView(icon: "lanyardcard.fill", title: "License", value: license)
                        }
                        
                        if let status = currentUser.status {
                            Divider().background(themeModel.divider)
                            InfoRowView(
                                icon: status == .active ? "checkmark.circle.fill" : "xmark.circle.fill",
                                title: "Status",
                                value: status.rawValue.capitalized,
                                valueColor: status == .active ? themeModel.success : themeModel.textSecondary
                            )
                        }
                        
                        if let date = currentUser.createdAt {
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
                        viewModel.deleteEmployee(currentUser)
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
            EditEmployeeView(user: currentUser, viewModel: viewModel)
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
            user: MockData.users.first(where: { $0.fullName == "Ravi Kumar" }) ?? MockData.users.first!,
            viewModel: EmployeesViewModel()
        )
        .preferredColorScheme(.dark)
    }
}
