//
//  AppleAuthorizationController.swift
//
//  Copyright © 2026 Alex Fargo.
//

import AuthenticationServices
import Foundation
import Observation

enum AppleAuthorizationError: LocalizedError {
  case unexpectedCredential(any ASAuthorizationCredential)
  case previewNotSupported

  var errorDescription: String? {
    switch self {
    case let .unexpectedCredential(credential):
      return "An unexpected credential was received: \(credential)"
    case .previewNotSupported:
      return "Apple authentication is not supported in SwiftUI previews"
    }
  }
}

public struct AppleAuthorizationController {
  public func requestAuthorization(with scopes: [ASAuthorization.Scope]? = nil, nonce: String?) async throws -> ASAuthorizationAppleIDCredential {
    // Fail early if running in SwiftUI previews
    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
      try await Task.sleep(for: .seconds(0.5))
      throw AppleAuthorizationError.previewNotSupported
    }

    let appleIDProvider = ASAuthorizationAppleIDProvider()
    let appleIDRequest = appleIDProvider.createRequest()
    appleIDRequest.requestedScopes = scopes
    appleIDRequest.nonce = nonce

    let delegate = AppleAuthenticationContinuationDelegate()
    let controller = ASAuthorizationController(authorizationRequests: [appleIDRequest])
    let authorizationResult = try await withCheckedThrowingContinuation { continuation in
      delegate.continuation = continuation
      controller.delegate = delegate
      controller.performRequests()
    }

    switch authorizationResult.credential {
    case let appleIDCredential as ASAuthorizationAppleIDCredential:
      return appleIDCredential
    default:
      throw AppleAuthorizationError.unexpectedCredential(authorizationResult.credential)
    }
  }
}

final class AppleAuthenticationContinuationDelegate: NSObject, ASAuthorizationControllerDelegate {
  var continuation: CheckedContinuation<ASAuthorization, Error>?

  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: any Error) {
    continuation?.resume(throwing: error)
    continuation = nil
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    continuation?.resume(returning: authorization)
    continuation = nil
  }
}
