//
//  SessionManagerScope.swift
//
//  Copyright © 2026 Alex Fargo.
//

import AuthenticationServices
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
      .onDeleteAccount {
        // Request Apple Sign In re-authentication
        let nonce = UUID().uuidString
        let controller = AppleAuthorizationController()
        let credential = try await controller.requestAuthorization(nonce: nonce)

        // Extract credentials from the Apple result
        guard
          let identityTokenData = credential.identityToken,
          let identityToken = String(data: identityTokenData, encoding: .utf8),
          let authorizationCodeData = credential.authorizationCode,
          let authorizationCode = String(data: authorizationCodeData, encoding: .utf8)
        else {
          throw SessionManagerError.missingAppleCredentials
        }

        let credentials = SignInWithAppleCredentials(
          identityToken: identityToken,
          authorizationCode: authorizationCode,
          nonce: nonce,
          fullName: nil,
          email: nil
        )

        try await sessionManager.deleteAccount(credentials: credentials)
      }
      .onUpdateProfile { fullName, displayName, imageData, mimeType in
        try await sessionManager.updateProfile(
          fullName: fullName,
          displayName: displayName,
          imageData: imageData,
          mimeType: mimeType
        )
      }
      .environment(sessionManager)
      .environment(\.accountDetails, sessionManager.accountDetails)
  }
}
