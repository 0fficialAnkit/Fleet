//
//  loginView.swift
//  Fleet
//
//  Created by Harshita Jiaswal on 19/05/26.
//
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

    @State private var selectedRoleId: Int = 1
    @State private var navigateToSignIn: Bool = false

    let roleItems: [RoleDisplayItem] = [
        RoleDisplayItem(
            id: 1,
            roleName: "Fleet Manager",
            description: "Manage fleet, drivers & analytics",
            iconName: "shield.fill",
            iconColor: .blue,
            iconBackground: Color.blue.opacity(0.25)
        ),
        RoleDisplayItem(
            id: 2,
            roleName: "Driver",
            description: "View routes, log trips & fuel",
            iconName: "truck.box.fill",
            iconColor: Color(red: 0.2, green: 0.85, blue: 0.45),
            iconBackground: Color.green.opacity(0.2)
        ),
        RoleDisplayItem(
            id: 3,
            roleName: "Maintenance",
            description: "Schedule repairs & manage parts",
            iconName: "wrench.and.screwdriver.fill",
            iconColor: .orange,
            iconBackground: Color.orange.opacity(0.2)
        )
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.09, blue: 0.13)
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
            .navigationDestination(isPresented: $navigateToSignIn) {

                if selectedRoleId == 1 {
                    SignInView(
                        selectedTab: .signIn,
                        showSignUp: true
                    )
                } else {
                    SignInView(
                        selectedTab: .signIn,
                        showSignUp: false
                    )
                }
            }
        }
    }
    // MARK: - App Icon (blue truck)
    var appIconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.blue)
                .frame(width: 80, height: 80)
            Image(systemName: "truck.box.fill")
                .font(.system(size: 36))
                .foregroundColor(.white)
        }
    }

    // MARK: - Title + Subtitle
    var titleSection: some View {
        VStack(spacing: 8) {
            Text("PrimeFleet")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)
            Text("Select your role to continue")
                .font(.system(size: 16))
                .foregroundColor(Color.white.opacity(0.5))
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
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.blue)
                .cornerRadius(16)
        }
    }

    // MARK: - Continue Action
    func handleContinue() {
//        navigateToSignIn = false
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            navigateToSignIn = true
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
                .foregroundColor(.white)
            Text(item.description)
                .font(.system(size: 14))
                .foregroundColor(Color.white.opacity(0.5))
        }
    }
    
    var selectionDot: some View {
        Circle()
            .fill(isSelected ? Color.blue : Color.clear)
            .overlay(
                Circle().stroke(
                    isSelected ? Color.blue : Color.white.opacity(0.25),
                    lineWidth: 1.5
                )
            )
            .frame(width: 22, height: 22)
    }
    
    var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                isSelected
                    ? Color(red: 0.1, green: 0.18, blue: 0.32)
                    : Color(red: 0.12, green: 0.14, blue: 0.18)
            )
    }

    var cardBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
    }
}

// MARK: - Preview
#Preview {
    LoginView()
        .environment(AuthViewModel())
}

