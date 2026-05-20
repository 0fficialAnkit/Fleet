//
//  ContentView.swift
//  Fleet
//
//  Created by Ankit Kumar on 13/05/26.
//

import SwiftUI

struct ContentView: View {
    @State private var authViewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                VStack {
                    Text("Welcome to FleetOS")
                        .font(.largeTitle)
                    
                    Text(authViewModel.currentUser?.email ?? "")
                    
                    Button("Sign Out") {
                        Task {
                            await authViewModel.signOut()
                        }
                    }
                    .padding()
                }
            } else {
                LoginView()
                    .environment(authViewModel)
            }
        }
        .task {
            await authViewModel.checkUserSession()
        }
    }
}

#Preview {
    ContentView()
}
