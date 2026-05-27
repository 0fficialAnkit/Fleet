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
        List(filteredEmployees) { profile in
            let roleName = viewModel.getRole(for: profile)

            NavigationLink(destination: EmployeeDetailView(profile: profile, viewModel: viewModel)) {
                EmployeeRowView(
                    profile: profile,
                    roleName: roleName,
                    icon: viewModel.getIcon(for: roleName),
                    iconColor: viewModel.getColor(for: roleName)
                )
            }
        }
        .listStyle(.insetGrouped)
        // If you need to match exactly the parent ZStack background:
        .scrollContentBackground(.hidden)
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
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        EmployeesView(viewModel: EmployeesViewModel(), roleFilter: "driver")
    }
}