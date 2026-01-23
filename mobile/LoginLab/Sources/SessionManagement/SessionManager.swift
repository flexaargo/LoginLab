//
//  SessionManager.swift
//
//  Copyright © 2026 Alex Fargo.
//

import Foundation
import Observation

/// Manages the user session and provides access to the session.
@Observable
public final class SessionManager {
  /// The current user session.
  public private(set) var userSession: UserSession?

  /// The networking client to use for API requests.
  private let networkingClient: NetworkingClient

  /// Initializes the session manager with a networking client.
  init(networkingClient: NetworkingClient) {
    self.networkingClient = networkingClient
  }

  /// Signs in with Apple using the provided credentials.
  public func signIn(credentials: SignInWithAppleCredentials) async throws {
    let response = try await networkingClient.signIn(
      identityToken: credentials.identityToken,
      authorizationCode: credentials.authorizationCode,
      nonce: credentials.nonce,
      fullName: credentials.fullName,
      email: credentials.email
    )

    userSession = UserSession(
      accountDetails: AccountDetails(
        userID: response.user.id,
        email: response.user.email,
        name: response.user.fullName
      ),
      accessToken: response.accessToken,
      refreshToken: response.refreshToken
    )
  }
}
