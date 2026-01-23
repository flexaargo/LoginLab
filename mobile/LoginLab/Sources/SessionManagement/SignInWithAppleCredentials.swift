//
//  SignInWithAppleCredentials.swift
//
//  Copyright © 2026 Alex Fargo.
//

import Foundation

/// Credentials required to Sign in with Apple.
public struct SignInWithAppleCredentials {
  /// The identity token provided by Apple.
  public let identityToken: String
  /// The authorization code provided by Apple.
  public let authorizationCode: String
  /// The nonce used for the authentication request.
  public let nonce: String
  /// The full name of the user. Must be provided if user is new.
  public let fullName: String?
  /// The email of the user. Must be provided if user is new.
  public let email: String?
}
