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
        List {
            // Header Profile Section
            Section {
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
                        .font(.title.bold())
                        .foregroundColor(Color.primary)

                    Text(currentRoleName)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(viewModel.getColor(for: currentRoleName))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(viewModel.getColor(for: currentRoleName).opacity(0.15))
                        .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets()) // Removes extra padding to let VStack center nicely
            }

            // Information Cards
            Section {
                InfoRowView(icon: "person.fill", title: "Full Name", value: currentProfile.fullName)
                InfoRowView(icon: "envelope.fill", title: "Email", value: currentProfile.email)
                InfoRowView(icon: "phone.fill", title: "Phone", value: currentProfile.phone ?? "Not Provided")

                if currentProfile.role == "driver" {
                    InfoRowView(icon: "lanyardcard.fill", title: "Driver License", value: currentProfile.licenseNumber ?? "Not Provided")
                }

                let status = currentProfile.userStatus ?? .active
                InfoRowView(
                    icon: status == .active ? "checkmark.circle.fill" : "xmark.circle.fill",
                    title: "Status / State",
                    value: status.rawValue.capitalized,
                    valueColor: status == .active ? Color.green : Color.secondary
                )

                if let date = currentProfile.createdAt {
                    InfoRowView(icon: "calendar", title: "Joined", value: date.formatted(date: .abbreviated, time: .omitted))
                }
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
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
                    Image(systemName: "ellipsis.circle")
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
                .foregroundColor(Color(.tertiaryLabel))
                .frame(width: 24)

            Text(title)
                .font(.body.weight(.medium))
                .foregroundColor(Color.secondary)

            Spacer()

            Text(value)
                .font(.body)
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