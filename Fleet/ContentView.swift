//
//  ContentView.swift
//  Fleet
//
//  Created by Ankit Kumar on 13/05/26.
//

import SwiftUI
import Supabase

struct ContentView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                if let role = authViewModel.userRole {
                    switch role {
                    case "fleet_manager":
                        AdminDashboardView(authViewModel: authViewModel)
                    case "driver":
                        DriverDashboardView(authViewModel: authViewModel)
                    case "maintenance":
                        MaintenanceDashboardView(authViewModel: authViewModel)
                    default:
                        UnknownRoleView(authViewModel: authViewModel)
                    }
                } else {
                    UnknownRoleView(authViewModel: authViewModel)
                }
            } else {
                LoginView()
            }
        }
        .task {
            await authViewModel.checkUserSession()
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthViewModel())
}


// MARK: - Placeholder Dashboards

struct PlaceholderDashboardView: View {
    let title: String
    let iconName: String
    let iconColor: Color
    @Bindable var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            // Dark background matching LoginView
            Color(red: 0.07, green: 0.09, blue: 0.13)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: iconName)
                        .font(.system(size: 32))
                        .foregroundColor(iconColor)
                }
                
                VStack(spacing: 8) {
                    Text("PLACEHOLDER SCREEN")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                        .kerning(1.2)
                    
                    Text(title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                
                // User info card
                VStack(spacing: 8) {
                    Text("Logged in as")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(authViewModel.currentUser?.email ?? "Unknown User")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .background(Color(red: 0.12, green: 0.14, blue: 0.18))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                
                Spacer()
                
                Button(action: {
                    Task { await authViewModel.signOut() }
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(16)
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
        }
    }
}

struct AdminDashboardView: View {
    @Bindable var authViewModel: AuthViewModel
    var body: some View {
        PlaceholderDashboardView(
            title: "Fleet Manager Dashboard",
            iconName: "shield.fill",
            iconColor: .blue,
            authViewModel: authViewModel
        )
    }
}

struct DriverDashboardView: View {
    @Bindable var authViewModel: AuthViewModel
    var body: some View {
        PlaceholderDashboardView(
            title: "Driver Dashboard",
            iconName: "truck.box.fill",
            iconColor: Color(red: 0.2, green: 0.85, blue: 0.45),
            authViewModel: authViewModel
        )
    }
}

struct MaintenanceDashboardView: View {
    @Bindable var authViewModel: AuthViewModel
    var body: some View {
        PlaceholderDashboardView(
            title: "Maintenance Dashboard",
            iconName: "wrench.and.screwdriver.fill",
            iconColor: .orange,
            authViewModel: authViewModel
        )
    }
}

struct UnknownRoleView: View {
    @Bindable var authViewModel: AuthViewModel
    var body: some View {
        PlaceholderDashboardView(
            title: "Unknown Role",
            iconName: "exclamationmark.triangle.fill",
            iconColor: .red,
            authViewModel: authViewModel
        )
    }
}
