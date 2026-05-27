import SwiftUI

struct FleetActivityLogView: View {
    let profiles: [Profile]
    let trips: [Trip]
    @State private var employeesViewModel = EmployeesViewModel()

    private var drivers:     [Profile] { profiles.filter { $0.role == "driver" } }
    private var maintenance: [Profile] { profiles.filter { $0.role == "maintenance" } }

    private var activeDriverIds: Set<UUID> {
        Set(trips.filter { $0.status == .active }.compactMap { $0.driverId })
    }

    var body: some View {
        List {
            if !drivers.isEmpty {
                Section(header: Text("Drivers")) {
                    ForEach(drivers) { profile in
                        employeeRow(profile)
                    }
                }
            }

            if !maintenance.isEmpty {
                Section(header: Text("Maintenance")) {
                    ForEach(maintenance) { profile in
                        employeeRow(profile)
                    }
                }
            }

            if profiles.isEmpty {
                Section {
                    VStack(spacing: 14) {
                        Image(systemName: "person.slash")
                            .font(.system(size: 40))
                            .foregroundStyle(Color(.quaternaryLabel))
                        Text("No employees found")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Fleet Activity Log")
        .navigationBarTitleDisplayMode(.large)
        .task {
            if employeesViewModel.profiles.isEmpty {
                await employeesViewModel.loadData()
            }
        }
    }

    @ViewBuilder
    private func employeeRow(_ profile: Profile) -> some View {
        let roleName    = employeesViewModel.getRole(for: profile)
        let icon        = employeesViewModel.getIcon(for: roleName)
        let color       = employeesViewModel.getColor(for: roleName)
        let isDriver    = profile.role == "driver"
        let onTrip      = isDriver && activeDriverIds.contains(profile.id)
        let statusLabel = isDriver ? (onTrip ? "On Trip" : "Idle") : "Active"
        let statusColor: Color = isDriver ? (onTrip ? .green : .orange) : .green

        NavigationLink {
            EmployeeDetailView(profile: profile, viewModel: employeesViewModel)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(profile.fullName)
                        .font(.body.bold())
                        .foregroundStyle(Color.primary)
                    Text(roleName)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(color)
                }

                Spacer()

                HStack(spacing: 5) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 7, height: 7)
                    Text(statusLabel)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
