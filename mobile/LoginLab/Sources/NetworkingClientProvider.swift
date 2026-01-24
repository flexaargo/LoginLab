//
//  NetworkingClientProvider.swift
//
//  Copyright © 2026 Alex Fargo.
//

import SwiftUI

@Observable
final class NetworkingClientProvider {
  private(set) var networkingClient: NetworkingClient

  init() {
    let client = NetworkingClient(
      host: "Alexs-MacBook-Pro.local",
      port: 3000,
      scheme: .http
    )
    self.networkingClient = client

    // Add logging middleware asynchronously
    // Since NetworkingClient is an actor, middleware will be added before any requests
    // (requests are also async and will be serialized on the actor)
    Task {
      await client.addMiddleware(LoggingMiddleware())
    }
  }
}
