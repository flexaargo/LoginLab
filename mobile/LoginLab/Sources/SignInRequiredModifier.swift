//
//  SignInRequiredModifier.swift
//
//  Copyright © 2026 Alex Fargo.
//

import SwiftUI

struct SignInRequiredModifier: ViewModifier {
  @Environment(\.accountDetails) private var accountDetails

  private var isSignInPresented: Binding<Bool> {
    .init {
      accountDetails == nil
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
