//
//  SignOutAction.swift
//
//  Copyright © 2026 Alex Fargo.
//

import Foundation
import SwiftUI

// MARK: - SignOutAction

public struct SignOutAction {
  let onSignOut: () async throws -> Void

  public func callAsFunction() async throws {
    try await onSignOut()
  }
}

// MARK: - Environment Value

public extension EnvironmentValues {
  @Entry var signOut = SignOutAction {
    throw NSError(
      domain: "SignOutAction",
      code: 0,
      userInfo: [NSLocalizedDescriptionKey: "Sign out action not implemented"]
    )
  }
}

extension View {
  /// Injects a sign out action into the environment.
  /// - Parameter action: The action to perform when the sign out button is pressed.
  func onSignOut(perform action: @escaping () async throws -> Void) -> some View {
    environment(\.signOut, SignOutAction(onSignOut: action))
  }
}
