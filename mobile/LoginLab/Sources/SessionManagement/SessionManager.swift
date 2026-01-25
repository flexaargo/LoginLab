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
  /// Whether the session manager has finished loading from storage.
  public private(set) var isInitialized = false

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

    Task {
      await initializeFromStorage()
      do {
        try await refreshTokensIfNeeded()
      } catch {
        print("🚨 Error refreshing tokens on startup: \(error)")
      }
    }
  }

  private func initializeFromStorage() async {
    defer { isInitialized = true }

    do {
      // Load account details
      if let storedAccountDetails = try await storage.getAccountDetails() {
        accountDetails = storedAccountDetails
      } else {
        print("⚠️ Account details not found in storage.")
      }

      // Load refresh token
      if let refreshToken = try await storage.getRefreshToken(),
         let refreshTokenExpiresAt = try await storage.getRefreshTokenExpiresAt()
      {
        userSession = UserSession(
          refreshToken: Token(
            token: refreshToken,
            expiresAt: refreshTokenExpiresAt
          )
        )
      } else {
        print("⚠️ Refresh token not found in storage.")
      }
    } catch {
      print("🚨 Error initializing from storage: \(error)")
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
      displayName: response.user.displayName,
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

  /// Deletes the current user's account. Requires fresh Apple Sign In credentials.
  /// Refreshes tokens if needed, calls the delete API, then clears local state.
  public func deleteAccount(credentials: SignInWithAppleCredentials) async throws {
    let networkingClient = networkingClientProvider.networkingClient
    try await refreshTokensIfNeeded()
    guard let accessToken = userSession?.accessToken?.token else {
      throw SessionManagerError.notAuthenticated
    }
    try await networkingClient.deleteAccount(
      accessToken: accessToken,
      identityToken: credentials.identityToken,
      authorizationCode: credentials.authorizationCode,
      nonce: credentials.nonce
    )
    try await storage.clear()
    accountDetails = nil
    userSession = nil
  }

  /// Signs out the current user and clears stored session data.
  public func signOut() async throws {
    let networkingClient = networkingClientProvider.networkingClient
    if let refreshToken = userSession?.refreshToken {
      try await networkingClient.signOut(refreshToken: refreshToken.token)
      try await storage.clear()
      accountDetails = nil
      userSession = nil
    } else {
      try await storage.clear()
      accountDetails = nil
      userSession = nil
    }
  }

  public func refreshTokensIfNeeded() async throws {
    guard let userSession else { return }
    let needsRefresh = {
      if let accessTokenExpiresAt = userSession.accessToken?.expiresAt {
        // expires in less than 90 seconds
        return accessTokenExpiresAt.addingTimeInterval(-90) < Date.now
      }
      return true
    }()
    if needsRefresh {
      try await forceRefreshTokens()
    }
  }

  public func forceRefreshTokens() async throws {
    guard let refreshToken = userSession?.refreshToken.token else { return }
    let networkingClient = networkingClientProvider.networkingClient

    let response = try await networkingClient.refreshTokens(refreshToken: refreshToken)

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
    try await storage.storeRefreshToken(userSession.refreshToken.token, expiresAt: userSession.refreshToken.expiresAt)

    self.userSession = userSession
  }
}
