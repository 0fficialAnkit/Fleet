//
//  ContentView.swift
//  Fleet
//
//  Created by Ankit Kumar on 13/05/26.
//

import SwiftUI
import Supabase

struct ContentView: View {
    @State private var authViewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if !authViewModel.isSessionChecked {
                ZStack {
                    Color(red: 0.07, green: 0.09, blue: 0.13).ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            } else if authViewModel.isAuthenticated {
                if let role = authViewModel.userRole {
                    switch role {
                    case "fleet_manager":
                        FleetManagerMainView()
                    case "driver":
                        DriverRootView()
                    case "maintenance":
                        MaintenanceRootView()
                    default:
                        VStack(spacing: 20) {
                            Text("Unknown Role")
                                .font(.title)
                            Button("Sign Out") {
                                Task { await authViewModel.signOut() }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                } else {
                    VStack(spacing: 20) {
                        Text("Unknown Role")
                            .font(.title)
                        Button("Sign Out") {
                            Task { await authViewModel.signOut() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                LoginView()
            }
        }
        .environment(authViewModel)
        .task {
            await authViewModel.checkUserSession()
        }
    }
}

#Preview {
    ContentView()
}
