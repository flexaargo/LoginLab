//
//  SessionManagerScope.swift
//
//  Copyright © 2026 Alex Fargo.
//

import SwiftUI

struct SessionManagerScope<Content: View>: View {
  @State private var sessionManager: SessionManager
  private let content: Content

  init(networkingClientProvider: NetworkingClientProvider, @ViewBuilder content: () -> Content) {
    self.content = content()
    self._sessionManager = State(initialValue: SessionManager(networkingClientProvider: networkingClientProvider))
  }

  var body: some View {
    content
      .environment(sessionManager)
      .environment(\.accountDetails, sessionManager.accountDetails)
  }
}
