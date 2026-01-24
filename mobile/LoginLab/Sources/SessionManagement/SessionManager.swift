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
  /// The account details for the current user.
  public private(set) var accountDetails: AccountDetails?

  /// The current session details.
  private var userSession: UserSession?

  /// The user can make authenticated requests.
  public var isAuthenticated: Bool { userSession != nil }

  /// The networking client to use for API requests.
  private let networkingClientProvider: NetworkingClientProvider

  /// The storage for persisting session data.
  private let storage = SessionStorage()

  /// Initializes the session manager with a networking client.
  init(networkingClientProvider: NetworkingClientProvider) {
    self.networkingClientProvider = networkingClientProvider

    initializeAccountDetails()
    initializeUserSession()
  }

  private func initializeAccountDetails() {
    Task {
      do {
        guard let accountDetails = try await storage.getAccountDetails() else {
          print("⚠️ Account details not found in storage.")
          return
        }

        self.accountDetails = accountDetails
      } catch {
        print("🚨 Error getting account details from storage: \(error)")
        self.accountDetails = nil
      }
    }
  }

  private func initializeUserSession() {
    Task {
      do {
        guard
          let refreshToken = try await storage.getRefreshToken(),
          let refreshTokenExpiresAt = try await storage.getRefreshTokenExpiresAt()
        else {
          print("⚠️ Refresh token not found in storage.")
          return
        }

        self.userSession = UserSession(
          refreshToken: Token(
            token: refreshToken,
            expiresAt: refreshTokenExpiresAt
          )
        )
      } catch {
        print("🚨 Error getting refresh token from storage: \(error)")
      }
    }
  }

  /// Signs in with Apple using the provided credentials.
  public func signIn(credentials: SignInWithAppleCredentials) async throws {
    let networkingClient = networkingClientProvider.networkingClient

    let response = try await networkingClient.signIn(
      identityToken: credentials.identityToken,
      authorizationCode: credentials.authorizationCode,
      nonce: credentials.nonce,
      fullName: credentials.fullName,
      email: credentials.email
    )

    let accountDetails = AccountDetails(
      userID: response.user.id,
      email: response.user.email,
      name: response.user.fullName
    )

    let userSession = UserSession(
      accessToken: Token(
        token: response.accessToken,
        expiresAt: response.accessTokenExpiresAt
      ),
      refreshToken: Token(
        token: response.refreshToken,
        expiresAt: response.refreshTokenExpiresAt
      )
    )

    // Store refresh token with expiration and user info persistently
    try await storage.storeRefreshToken(userSession.refreshToken.token, expiresAt: userSession.refreshToken.expiresAt)
    try await storage.storeAccountDetails(accountDetails)

    // Keep access token in memory only
    self.accountDetails = accountDetails
    self.userSession = userSession
  }

  /// Signs out the current user and clears stored session data.
  public func signOut() async throws {
    try await storage.clear()
    accountDetails = nil
    userSession = nil
  }
}
