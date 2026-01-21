//
//  SignInView.swift
//
//  Copyright © 2026 Alex Fargo.
//

import AuthenticationServices
import SwiftUI

struct SignInView: View {
  @State private var isAuthenticating = false
  @State private var nonce: String?

  var body: some View {
    NavigationStack {
      VStack {
        AppleAuthorizationButton(scopes: [.fullName, .email]) { result in
          switch result {
          case let .success(result):
            guard
              let identityToken = result.identityToken,
              let authorizationCode = result.authorizationCode,
              let nonce
            else {
              print("Missing data to complete sign in.")
              return
            }
            isAuthenticating = true
            Task {
              let client = NetworkingClient()
              do {
                let fullName = result.credential.fullName?.formatted()
                let email = result.credential.email
                try await client.signIn(
                  identityToken: identityToken,
                  authorizationCode: authorizationCode,
                  nonce: nonce,
                  fullName: fullName,
                  email: email
                )
              } catch {
                print("Error signing in: \(error)")
              }
              isAuthenticating = false
            }
          case let .failure(error):
            print("Authorization failed: \(error)")
          }
        } generateNonce: {
          nonce = UUID().uuidString
          return nonce
        }
        .appleAuthenticationButtonForceShowProgressIndiciator(isAuthenticating)
      }
      .disabled(isAuthenticating)
      .safeAreaPadding()
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
      .navigationTitle("Sign In")
      .toolbarTitleDisplayMode(.inlineLarge)
    }
  }
}

#Preview {
  SignInView()
}
