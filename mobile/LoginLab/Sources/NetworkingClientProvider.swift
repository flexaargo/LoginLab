//
//  NetworkingClientProvider.swift
//
//  Copyright © 2026 Alex Fargo.
//

import SwiftUI

@Observable
final class NetworkingClientProvider {
  private(set) var networkingClient = NetworkingClient(
    host: "Alexs-MacBook-Pro.local",
    port: 3000,
    scheme: .http
  )
}
