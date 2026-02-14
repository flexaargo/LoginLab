//
//  UpdateProfileAction.swift
//
//  Copyright © 2026 Alex Fargo.
//

import Foundation
import SwiftUI

// MARK: - UpdateProfileAction

public struct UpdateProfileAction {
  let onUpdateProfile: (
    _ fullName: String?,
    _ displayName: String?,
    _ imageData: Data?,
    _ mimeType: String?
  ) async throws -> Void

  public func callAsFunction(
    fullName: String? = nil,
    displayName: String? = nil,
    imageData: Data? = nil,
    mimeType: String? = nil
  ) async throws {
    try await onUpdateProfile(fullName, displayName, imageData, mimeType)
  }
}

// MARK: - Environment Value

public extension EnvironmentValues {
  @Entry var updateProfile = UpdateProfileAction { _, _, _, _ in
    throw NSError(
      domain: "UpdateProfileAction",
      code: 0,
      userInfo: [NSLocalizedDescriptionKey: "Update profile action not implemented"]
    )
  }
}

extension View {
  /// Injects an update profile action into the environment.
  /// - Parameter action: The action to perform when profile fields are updated.
  func onUpdateProfile(
    perform action: @escaping (
      _ fullName: String?,
      _ displayName: String?,
      _ imageData: Data?,
      _ mimeType: String?
    ) async throws -> Void
  ) -> some View {
    environment(
      \.updateProfile,
      UpdateProfileAction(onUpdateProfile: action)
    )
  }
}
