//
//  SignInRequiredModifier.swift
//
//  Copyright © 2026 Alex Fargo.
//

import SwiftUI

struct SignInRequiredModifier: ViewModifier {
  @Environment(SessionManager.self) private var sessionManager

  /// Only present sign-in after initialization completes and there's no account.
  private var isSignInPresented: Binding<Bool> {
    .init {
      sessionManager.isInitialized && sessionManager.accountDetails == nil
    } set: { _ in
      // NO OP
    }
  }

  func body(content: Content) -> some View {
    content
      .fullScreenCover(isPresented: isSignInPresented) {
        SignInView()
      }
  }
}

extension View {
  /// Presents a sign-in screen when the user session is not available.
  func requiresSignIn() -> some View {
    modifier(SignInRequiredModifier())
  }
}

#Preview {
  Text("Content")
    .requiresSignIn()
}
