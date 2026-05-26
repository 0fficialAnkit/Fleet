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
                Color(.systemGroupedBackground).ignoresSafeArea()

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
                    .font(.headline)
                    .foregroundColor(Color.primary)

                Text(roleName)
                    .font(.subheadline)
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
                .foregroundColor(Color(.tertiaryLabel))
        }
//        .padding(16)
//        .background(Color(.systemBackground))
//        .cornerRadius(20)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

    }
}

#Preview {
    NavigationStack {
        EmployeesView(viewModel: EmployeesViewModel(), roleFilter: "driver")
    }
}