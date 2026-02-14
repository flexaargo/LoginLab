//
//  SessionManager.swift
//
//  Copyright © 2026 Alex Fargo.
//

import Foundation
import Observation
import UIKit

/// Manages the user session and provides access to the session.
@Observable
public final class SessionManager {
  /// Whether the session manager has finished loading from storage.
  public private(set) var isInitialized = false

  /// The account details for the current user.
  public private(set) var accountDetails: AccountDetails?
  public private(set) var profileImage: UIImage?

  /// The current session details.
  private var userSession: UserSession?

  /// The user can make authenticated requests.
  public var isAuthenticated: Bool { userSession != nil }

  /// The networking client to use for API requests.
  private let networkingClientProvider: NetworkingClientProvider

  /// The storage for persisting session data.
  private let storage = SessionStorage()
  private let profileImageStore = ProfileImageStore()

  /// Initializes the session manager with a networking client.
  init(networkingClientProvider: NetworkingClientProvider) {
    self.networkingClientProvider = networkingClientProvider

    Task {
      await initializeFromStorage()
      do {
        try await refreshTokensIfNeeded()
        try await refreshCurrentUser()
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
        profileImage = await profileImageStore.loadImage(for: storedAccountDetails.userID)
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
      name: response.user.fullName,
      profileImageUrl: response.user.profileImageUrl
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
    await refreshProfileImage(for: accountDetails)
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
    if let userID = accountDetails?.userID {
      await profileImageStore.removeImage(for: userID)
    }
    try await storage.clear()
    accountDetails = nil
    profileImage = nil
    userSession = nil
  }

  /// Signs out the current user and clears stored session data.
  public func signOut() async throws {
    let networkingClient = networkingClientProvider.networkingClient
    if let refreshToken = userSession?.refreshToken {
      try await networkingClient.signOut(refreshToken: refreshToken.token)
      if let userID = accountDetails?.userID {
        await profileImageStore.removeImage(for: userID)
      }
      try await storage.clear()
      accountDetails = nil
      profileImage = nil
      userSession = nil
    } else {
      if let userID = accountDetails?.userID {
        await profileImageStore.removeImage(for: userID)
      }
      try await storage.clear()
      accountDetails = nil
      profileImage = nil
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

  /// Updates the user's profile. All parameters are optional; only provided values are updated.
  public func updateProfile(
    fullName: String? = nil,
    displayName: String? = nil,
    imageData: Data? = nil,
    mimeType: String? = nil
  ) async throws {
    let networkingClient = networkingClientProvider.networkingClient
    try await refreshTokensIfNeeded()
    guard let accessToken = userSession?.accessToken?.token else {
      throw SessionManagerError.notAuthenticated
    }

    let user = try await networkingClient.updateProfile(
      accessToken: accessToken,
      fullName: fullName,
      displayName: displayName,
      imageData: imageData,
      mimeType: mimeType
    )

    guard let existingAccountDetails = accountDetails else {
      return
    }

    let updatedAccountDetails = AccountDetails(
      userID: existingAccountDetails.userID,
      displayName: user.displayName,
      email: user.email,
      name: user.fullName,
      profileImageUrl: user.profileImageUrl
    )

    try await storage.storeAccountDetails(updatedAccountDetails)
    accountDetails = updatedAccountDetails
    await refreshProfileImage(for: updatedAccountDetails)
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

  public func refreshCurrentUserInBackground() async {
    do {
      try await refreshCurrentUser()
    } catch {
      print("⚠️ Failed refreshing current user: \(error)")
    }
  }

  public func refreshCurrentUser() async throws {
    guard userSession != nil else { return }

    let networkingClient = networkingClientProvider.networkingClient
    try await refreshTokensIfNeeded()
    guard let accessToken = userSession?.accessToken?.token else {
      throw SessionManagerError.notAuthenticated
    }

    let user = try await networkingClient.fetchCurrentUser(accessToken: accessToken)
    let updatedAccountDetails = AccountDetails(
      userID: user.id,
      displayName: user.displayName,
      email: user.email,
      name: user.fullName,
      profileImageUrl: user.profileImageUrl
    )

    try await storage.storeAccountDetails(updatedAccountDetails)
    accountDetails = updatedAccountDetails
    await refreshProfileImage(for: updatedAccountDetails)
  }

  private func refreshProfileImage(for accountDetails: AccountDetails) async {
    if let fetchedImage = await profileImageStore.fetchAndCacheImage(
      from: accountDetails.profileImageUrl,
      for: accountDetails.userID
    ) {
      profileImage = fetchedImage
      return
    }

    profileImage = await profileImageStore.loadImage(for: accountDetails.userID)
  }
}
