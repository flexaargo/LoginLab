//
//  UserSession.swift
//
//  Copyright © 2026 Alex Fargo.
//

import Foundation

/// A token with an expiration date.
nonisolated struct Token: Hashable, Sendable {
  let token: String
  let expiresAt: Date
}

/// A user session with an access token and refresh token.
nonisolated struct UserSession: Hashable, Sendable {
  var accessToken: Token?
  var refreshToken: Token
}
