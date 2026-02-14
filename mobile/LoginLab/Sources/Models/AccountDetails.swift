//
//  AccountDetails.swift
//
//  Copyright © 2026 Alex Fargo.
//

import Foundation
import SwiftUI
import UIKit

// MARK: - AccountDetails

public nonisolated struct AccountDetails: Hashable, Sendable {
  public let userID: String
  public let displayName: String
  public let email: String
  public let name: String
  public let profileImageUrl: String?
}

// MARK: - Environment Value

public extension EnvironmentValues {
  @Entry var accountDetails: AccountDetails?
  @Entry var profileImage: UIImage?
}

// MARK: - Preview Helpers

extension AccountDetails {
  static let previewUser = AccountDetails(
    userID: UUID().uuidString,
    displayName: "testuser",
    email: "test@example.com",
    name: "Test User",
    profileImageUrl: nil
  )
}
