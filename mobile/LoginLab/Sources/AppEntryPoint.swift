//
//  AppEntryPoint.swift
//
//  Copyright © 2026 Alex Fargo.
//

import SwiftUI

@main
struct AppEntryPoint: App {
  @State private var networkingClientProvider = NetworkingClientProvider()

  var body: some Scene {
    WindowGroup {
      SessionManagerScope(networkingClient: networkingClientProvider.networkingClient) {
        ContentView()
          .requiresSignIn()
      }
      .environment(networkingClientProvider)
    }
  }
}
