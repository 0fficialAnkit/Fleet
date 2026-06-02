import SwiftUI

// MARK: - RoleDisplayItem
struct RoleDisplayItem: Identifiable {
    let id: Int
    let roleName: String
    let description: String
    let iconName: String
    let iconColor: Color
    let iconBackground: Color
}

// MARK: - LoginView
struct LoginView: View {

    enum Destination: Hashable {
        case signIn(roleId: Int)
        case createAccount
    }

    @State private var selectedRoleId: Int = 1
    @State private var navigationPath = [Destination]()

    let roleItems: [RoleDisplayItem] = [
        RoleDisplayItem(
            id: 1,
            roleName: "Fleet Manager",
            description: "Manage fleet, drivers & analytics",
            iconName: "shield.fill",
            iconColor: Color.teal,
            iconBackground: Color.teal.opacity(0.15)
        ),
        RoleDisplayItem(
            id: 2,
            roleName: "Driver",
            description: "View routes, log trips & fuel",
            iconName: "truck.box.fill",
            iconColor: Color.green,
            iconBackground: Color.green.opacity(0.15)
        ),
        RoleDisplayItem(
            id: 3,
            roleName: "Maintenance",
            description: "Schedule repairs & manage parts",
            iconName: "wrench.and.screwdriver.fill",
            iconColor: Color.brown,
            iconBackground: Color.brown.opacity(0.15)
        )
    ]

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()
                    appIconView
                    Spacer().frame(height: 20)
                    titleSection
                    Spacer().frame(height: 40)
                    roleCardList
                    Spacer().frame(height: 40)
                    continueButton
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 24)
            }
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .signIn(let roleId):
                    SignInView(roleId: roleId)
                case .createAccount:
                    CreateAccountView(onSuccess: {
                        navigationPath = [.signIn(roleId: selectedRoleId)]
                    })
                }
            }
        }
    }
    // MARK: - App Icon (blue truck)
    var appIconView: some View {
        Button(action: {
            navigationPath.append(.createAccount)
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.teal)
                    .frame(width: 80, height: 80)
                Image(systemName: "truck.box.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Color(.systemBackground))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Title + Subtitle
    var titleSection: some View {
        VStack(spacing: 8) {
            Text("GoFleet")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(Color.primary)
            Text("Select your role to continue")
                .font(.system(size: 16))
                .foregroundColor(Color.secondary)
        }
    }

    // MARK: - All Role Cards
    var roleCardList: some View {
        VStack(spacing: 14) {
            ForEach(roleItems) { item in
                RoleCardView(
                    item: item,
                    isSelected: selectedRoleId == item.id
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedRoleId = item.id
                    }
                }
            }
        }
    }

    // MARK: - Continue Button
    var continueButton: some View {
        Button(action: handleContinue) {
            Text("Continue")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(.systemBackground))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.teal)
                .cornerRadius(16)
        }
    }

    // MARK: - Continue Action
    func handleContinue() {
        navigationPath.append(.signIn(roleId: selectedRoleId))
    }
}

// MARK: - RoleCardView
struct RoleCardView: View {
    let item: RoleDisplayItem
    let isSelected: Bool
    var body: some View {
        HStack(spacing: 16) {
            iconBox
            labelStack
            Spacer()
            selectionDot
        }
        .padding(16)
        .background(cardBackground)
        .overlay(cardBorder)
        .cornerRadius(16)
    }

    var iconBox: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(item.iconBackground)
                .frame(width: 52, height: 52)
            Image(systemName: item.iconName)
                .font(.system(size: 22))
                .foregroundColor(item.iconColor)
        }
    }

    var labelStack: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.roleName)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color.primary)
            Text(item.description)
                .font(.system(size: 14))
                .foregroundColor(Color.secondary)
        }
    }

    var selectionDot: some View {
        Circle()
            .fill(isSelected ? Color.teal : Color.clear)
            .overlay(
                Circle().stroke(
                    isSelected ? Color.teal : Color(.opaqueSeparator),
                    lineWidth: 1.5
                )
            )
            .frame(width: 22, height: 22)
    }

    var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                isSelected
                    ? Color.teal.opacity(0.12)
                    : Color(.systemBackground)
            )
    }

    var cardBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(isSelected ? Color.teal : Color.clear, lineWidth: 1.5)
    }
}

// MARK: - Preview
#Preview {
    LoginView()
        .environment(AuthViewModel())
}