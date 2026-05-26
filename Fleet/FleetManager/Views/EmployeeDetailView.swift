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
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header Profile Section
                    VStack(spacing: 8) {
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
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Color.primary)
                        
                        Text(currentRoleName)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(viewModel.getColor(for: currentRoleName))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(viewModel.getColor(for: currentRoleName).opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .padding(.top, 32)
                    
                    // Information Cards
                    VStack(spacing: 16) {
                        InfoRowView(icon: "person.fill", title: "Full Name", value: currentProfile.fullName)
                        
                        Divider().background(Color(UIColor.separator))
                        InfoRowView(icon: "envelope.fill", title: "Email", value: currentProfile.email)
                        
                        Divider().background(Color(UIColor.separator))
                        InfoRowView(icon: "phone.fill", title: "Phone", value: currentProfile.phone ?? "Not Provided")
                        
                        if currentProfile.role == "driver" {
                            Divider().background(Color(UIColor.separator))
                            InfoRowView(icon: "lanyardcard.fill", title: "Driver License", value: currentProfile.licenseNumber ?? "Not Provided")
                        }
                        
                        Divider().background(Color(UIColor.separator))
                        let status = currentProfile.userStatus ?? .active
                        InfoRowView(
                            icon: status == .active ? "checkmark.circle.fill" : "xmark.circle.fill",
                            title: "Status / State",
                            value: status.rawValue.capitalized,
                            valueColor: status == .active ? Color.green : Color.secondary
                        )
                        
                        if let date = currentProfile.createdAt {
                            Divider().background(Color(UIColor.separator))
                            InfoRowView(icon: "calendar", title: "Joined", value: date.formatted(date: .abbreviated, time: .omitted))
                        }
                    }
//                    .padding(16)
//                    .background(Color(UIColor.systemBackground))
//                    .cornerRadius(20)
//                    .padding(.horizontal, 16)
                    .padding(16)
                    .background(
                        Color(UIColor.tertiarySystemBackground).opacity(0.35)
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 20,
                            style: .continuous
                        )
                    )
                    .glassEffect(
                        in: RoundedRectangle(
                            cornerRadius: 20,
                            style: .continuous
                        )
                    )
                    .overlay(
                        RoundedRectangle(
                            cornerRadius: 20,
                            style: .continuous
                        )
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
                    .padding(.horizontal, 16)
                }
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(UIColor.systemGroupedBackground), for: .navigationBar)
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
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color.primary)
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
    var valueColor: Color = Color.primary
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(UIColor.tertiaryLabel))
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(Color.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .regular, design: .rounded))
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
