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
        case signIn
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
            iconColor: themeModel.accent,
            iconBackground: themeModel.accent.opacity(0.15)
        ),
        RoleDisplayItem(
            id: 2,
            roleName: "Driver",
            description: "View routes, log trips & fuel",
            iconName: "truck.box.fill",
            iconColor: themeModel.driverPrimary,
            iconBackground: themeModel.driverPrimary.opacity(0.15)
        ),
        RoleDisplayItem(
            id: 3,
            roleName: "Maintenance",
            description: "Schedule repairs & manage parts",
            iconName: "wrench.and.screwdriver.fill",
            iconColor: themeModel.maintenancePrimary,
            iconBackground: themeModel.maintenancePrimary.opacity(0.15)
        )
    ]

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                themeModel.backgroundPrimary
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
                case .signIn:
                    SignInView()
                case .createAccount:
                    CreateAccountView(onSuccess: {
                        navigationPath = [.signIn]
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
                    .fill(themeModel.accent)
                    .frame(width: 80, height: 80)
                Image(systemName: "truck.box.fill")
                    .font(.system(size: 36))
                    .foregroundColor(themeModel.accentForeground)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Title + Subtitle
    var titleSection: some View {
        VStack(spacing: 8) {
            Text("GoFleet")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(themeModel.textPrimary)
            Text("Select your role to continue")
                .font(.system(size: 16))
                .foregroundColor(themeModel.textSecondary)
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
                .foregroundColor(themeModel.accentForeground)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(themeModel.accent)
                .cornerRadius(16)
        }
    }

    // MARK: - Continue Action
    func handleContinue() {
        navigationPath.append(.signIn)
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
                .foregroundColor(themeModel.textPrimary)
            Text(item.description)
                .font(.system(size: 14))
                .foregroundColor(themeModel.textSecondary)
        }
    }
    
    var selectionDot: some View {
        Circle()
            .fill(isSelected ? themeModel.accent : Color.clear)
            .overlay(
                Circle().stroke(
                    isSelected ? themeModel.accent : themeModel.border,
                    lineWidth: 1.5
                )
            )
            .frame(width: 22, height: 22)
    }
    
    var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                isSelected
                    ? themeModel.accent.opacity(0.12)
                    : themeModel.backgroundElevated
            )
    }

    var cardBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(isSelected ? themeModel.accent : Color.clear, lineWidth: 1.5)
    }
}

// MARK: - Preview
#Preview {
    LoginView()
        .environment(AuthViewModel())
}
