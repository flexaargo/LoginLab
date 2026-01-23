//
//  SessionManagerScope.swift
//
//  Copyright © 2026 Alex Fargo.
//

import SwiftUI

struct SessionManagerScope<Content: View>: View {
  @State private var sessionManager: SessionManager
  private let networkingClient: NetworkingClient
  private let content: Content

  init(networkingClient: NetworkingClient, @ViewBuilder content: () -> Content) {
    self.networkingClient = networkingClient
    self.content = content()
    self._sessionManager = State(initialValue: SessionManager(networkingClient: networkingClient))
  }

  var body: some View {
    content
      .environment(sessionManager)
      .environment(\.userSession, sessionManager.userSession)
      .environment(\.accountDetails, sessionManager.userSession?.accountDetails)
  }
}
