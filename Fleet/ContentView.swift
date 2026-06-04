//
//  ContentView.swift
//  Fleet
//
//  Created by Ankit Kumar on 13/05/26.
//

import SwiftUI
import Supabase
import CoreLocation

struct ContentView: View {
    @State private var authViewModel = AuthViewModel()
    @Environment(\.scenePhase) private var scenePhase
    // Single shared LocationManager at the app root.
    // Requesting permission here fires the native dialog as soon as the user
    // is authenticated — before any map view even renders.
    @State private var locationManager = LocationManager()
    @State private var showSplash = true

    var body: some View {
        ZStack {
            Group {
                if !authViewModel.isSessionChecked {
                    ZStack {
                        Color(.systemBackground).ignoresSafeArea()
                        ProgressView()
                            .tint(Color.primary)
                    }
                } else if authViewModel.isAuthenticated {
                    if let roleName = authViewModel.resolvedRoleName {
                        switch roleName.lowercased() {
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
                if authViewModel.isAuthenticated {
                    // Ask for location right after login resolves — shows the
                    // native "Allow location access" dialog immediately on first launch.
                    locationManager.requestPermission()
                    await RealtimeManager.shared.subscribeAll()
                }
            }
            
            if showSplash {
                SplashVideoView(isActive: $showSplash)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
    }
}

#Preview {
    ContentView()
}