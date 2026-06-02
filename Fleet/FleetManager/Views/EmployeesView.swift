import SwiftUI

// MARK: - Sort Options
enum EmployeeSortOption {
    case dateAddedLatest
    case dateAddedOldest
    case nameAZ
    case nameZA
}

// MARK: - Employees List

struct EmployeesView: View {
    var viewModel: EmployeesViewModel
    /// `nil` = show all; `"driver"` or `"maintenance"` = filter by role.
    let roleFilter: String?
    let sortOption: EmployeeSortOption

    private var employees: [Profile] {
        var result = viewModel.employees
        if let filter = roleFilter {
            result = result.filter { $0.role.lowercased() == filter.lowercased() }
        }
        
        result.sort { p1, p2 in
            switch sortOption {
            case .dateAddedLatest:
                return (p1.createdAt ?? .distantPast) > (p2.createdAt ?? .distantPast)
            case .dateAddedOldest:
                return (p1.createdAt ?? .distantPast) < (p2.createdAt ?? .distantPast)
            case .nameAZ:
                return p1.fullName.localizedStandardCompare(p2.fullName) == .orderedAscending
            case .nameZA:
                return p1.fullName.localizedStandardCompare(p2.fullName) == .orderedDescending
            }
        }
        
        return result
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.employees.isEmpty {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if employees.isEmpty {
                ContentUnavailableView(
                    "No Employees",
                    systemImage: "person.2.slash",
                    description: Text("No employees found matching the selected filter.")
                )
            } else {
                employeeList
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    private var employeeList: some View {
        List(employees) { profile in
            NavigationLink(value: profile) {
                EmployeeRowView(
                    profile: profile,
                    roleIcon: viewModel.getRoleIcon(for: profile),
                    roleIconColor: viewModel.getColor(for: profile.role),
                    statusText: viewModel.getOperationalStatusText(for: profile),
                    statusColor: viewModel.getOperationalStatusColor(for: profile)
                )
            }
        }
        .listStyle(.insetGrouped)
        .navigationDestination(for: Profile.self) { profile in
            EmployeeDetailView(profile: profile, viewModel: viewModel)
        }
    }
}

// MARK: - Employee Row

struct EmployeeRowView: View {
    let profile: Profile
    let roleIcon: String
    let roleIconColor: Color
    let statusText: String
    let statusColor: Color

    var body: some View {
        HStack(spacing: 14) {
            // Role avatar
            Image(systemName: roleIcon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(roleIconColor)
                .frame(width: 44, height: 44)
                .background(roleIconColor.opacity(0.12), in: Circle())

            // Name label (removed role subtitle)
            VStack(alignment: .leading, spacing: 3) {
                Text(profile.fullName)
                    .font(.body.weight(.semibold))
            }

            Spacer(minLength: 0)

            StatusBadge(text: statusText, color: statusColor)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Previews

#Preview("All employees") {
    NavigationStack {
        EmployeesView(viewModel: EmployeesViewModel(), roleFilter: nil, sortOption: .dateAddedLatest)
            .navigationTitle("Fleet")
    }
}

#Preview("Drivers only") {
    NavigationStack {
        EmployeesView(viewModel: EmployeesViewModel(), roleFilter: "driver", sortOption: .nameAZ)
            .navigationTitle("Drivers")
    }
}