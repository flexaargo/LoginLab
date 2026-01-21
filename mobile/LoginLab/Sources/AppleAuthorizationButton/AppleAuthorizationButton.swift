//
//  AppleAuthorizationButton.swift
//
//  Copyright © 2026 Alex Fargo.
//

import AuthenticationServices
import SwiftUI

struct AppleAuthorizationButton: View {
  @Environment(\.appleAuthorizationButtonConfig) private var config
  @State private var isAuthenticating = false
  private let scopes: [ASAuthorization.Scope]?
  private let onComplete: (Result<AppleAuthorizationResult, any Error>) -> Void
  private let generateNonce: (() -> String?)?

  init(
    scopes: [ASAuthorization.Scope]? = nil,
    onComplete: @escaping (Result<AppleAuthorizationResult, any Error>) -> Void,
    generateNonce: (() -> String?)? = nil
  ) {
    self.scopes = scopes
    self.generateNonce = generateNonce
    self.onComplete = onComplete
  }

  var body: some View {
    Button {
      guard !isAuthenticating else { return }
      isAuthenticating = true
      Task {
        let controller = AppleAuthorizationController()
        do {
          let nonce = generateNonce?()
          let credential = try await controller.requestAuthorization(with: scopes, nonce: nonce)
          onComplete(.success(AppleAuthorizationResult(credential: credential, nonce: nonce)))
        } catch {
          onComplete(.failure(error))
        }
        isAuthenticating = false
      }
    } label: {
      Label("Sign in with Apple", systemImage: "applelogo")
        .opacity(shouldShowProgressIndicator ? 0 : 1)
        .overlay {
          if shouldShowProgressIndicator {
            ProgressView()
          }
        }
        .animation(nil, value: shouldShowProgressIndicator)
    }
    .buttonStyle(.appleAuthentication)
    .disabled(isAuthenticating)
  }

  private var shouldShowProgressIndicator: Bool {
    (config.showsProgressIndiciator && isAuthenticating) || config.forceShowProgressIndiciator
  }
}
