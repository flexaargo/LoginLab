//
//  SessionManagerScope.swift
//
//  Copyright © 2026 Alex Fargo.
//

import SwiftUI

public struct SessionManagerScope<Content: View>: View {
  @State private var sessionManager: SessionManager
  private let content: Content

  init(networkingClientProvider: NetworkingClientProvider, @ViewBuilder content: () -> Content) {
    self.content = content()
    self._sessionManager = State(initialValue: SessionManager(networkingClientProvider: networkingClientProvider))
  }

  public var body: some View {
    content
      .onSignOut {
        try await sessionManager.signOut()
      }
      .environment(sessionManager)
      .environment(\.accountDetails, sessionManager.accountDetails)
  }
}
