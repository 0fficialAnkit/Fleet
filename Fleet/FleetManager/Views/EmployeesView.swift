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
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
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
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
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
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.fullName)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.primary)
                
                Text(roleName)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(Color.secondary)
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
                .foregroundColor(Color(UIColor.tertiaryLabel))
        }
//        .padding(16)
//        .background(Color(UIColor.systemBackground))
//        .cornerRadius(20)
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
    }
}

#Preview {
    NavigationStack {
        EmployeesView(viewModel: EmployeesViewModel(), roleFilter: "driver")
    }
}
