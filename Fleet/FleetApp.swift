//
//  FleetApp.swift
//  Fleet
//
//  Created by Ankit Kumar on 13/05/26.
//

import SwiftUI

@main
struct FleetApp: App {
    @State private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authViewModel)
        }
    }
}
