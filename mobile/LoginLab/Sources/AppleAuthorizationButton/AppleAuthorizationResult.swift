//
//  AppleAuthorizationResult.swift
//
//  Copyright © 2026 Alex Fargo.
//

import AuthenticationServices
import Foundation

/// Object returned when the user has successfully completed the Sign in with Apple authorization flow.
public struct AppleAuthorizationResult {
  /// The credential returned by the Apple authentication controller.
  public let credential: ASAuthorizationAppleIDCredential
  /// The nonce used for the authentication request.
  public let nonce: String?
}

public extension AppleAuthorizationResult {
  /// A JSON Web Token (JWT) that securely communicates information about the user to the app.
  var identityToken: String? {
    guard let identityTokenData = credential.identityToken else { return nil }
    return String(data: identityTokenData, encoding: .utf8)
  }

  /// The authorization code provided by Apple which is used to exchange for an access token from Apple.
  var authorizationCode: String? {
    guard let authorizationCodeData = credential.authorizationCode else { return nil }
    return String(data: authorizationCodeData, encoding: .utf8)
  }
}
