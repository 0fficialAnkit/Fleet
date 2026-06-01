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
            NavigationLink(destination: EmployeeDetailView(profile: profile, viewModel: viewModel)) {
                EmployeeRowView(
                    profile: profile,
                    roleName: viewModel.getRole(for: profile),
                    statusText: viewModel.getOperationalStatusText(for: profile),
                    statusColor: viewModel.getOperationalStatusColor(for: profile)
                )
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
}

struct EmployeeRowView: View {
    let profile: Profile
    let roleName: String
    let statusText: String
    let statusColor: Color

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.fullName)
                    .font(.headline)
                    .foregroundStyle(Color.primary)

                Text(roleName)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            }

            Spacer()

            StatusBadge(text: statusText, color: statusColor)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        EmployeesView(viewModel: EmployeesViewModel(), roleFilter: "driver")
    }
}