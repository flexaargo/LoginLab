//
//  DeleteAccountAction.swift
//
//  Copyright © 2026 Alex Fargo.
//

import Foundation
import SwiftUI

// MARK: - DeleteAccountAction

public struct DeleteAccountAction {
  let onDeleteAccount: () async throws -> Void

  public func callAsFunction() async throws {
    try await onDeleteAccount()
  }
}

// MARK: - Environment Value

public extension EnvironmentValues {
  @Entry var deleteAccount = DeleteAccountAction {
    throw NSError(
      domain: "DeleteAccountAction",
      code: 0,
      userInfo: [NSLocalizedDescriptionKey: "Delete account action not implemented"]
    )
  }
}

extension View {
  /// Injects a delete account action into the environment.
  /// The action will handle the Apple Sign In re-authentication flow internally.
  /// - Parameter action: The action to perform when delete account is requested.
  func onDeleteAccount(perform action: @escaping () async throws -> Void) -> some View {
    environment(\.deleteAccount, DeleteAccountAction(onDeleteAccount: action))
  }
}
