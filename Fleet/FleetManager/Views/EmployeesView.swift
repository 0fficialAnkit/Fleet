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
            let isActive: Bool = {
                if profile.role == "driver" {
                    return viewModel.activeDriverIds.contains(profile.id)
                }
                return true // maintenance is always active
            }()

            NavigationLink(destination: EmployeeDetailView(profile: profile, viewModel: viewModel)) {
                EmployeeRowView(
                    profile: profile,
                    roleName: viewModel.getRole(for: profile),
                    isActive: isActive
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
    let isActive: Bool

    private var statusLabel: String {
        if profile.role == "driver" {
            return isActive ? "On Trip" : "Idle"
        }
        return isActive ? "Active" : "Idle"
    }

    private var statusColor: Color {
        isActive ? .green : .orange
    }

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

            StatusBadge(text: statusLabel, color: statusColor)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        EmployeesView(viewModel: EmployeesViewModel(), roleFilter: "driver")
    }
}