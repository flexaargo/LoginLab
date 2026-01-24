//
//  AccountDetails.swift
//
//  Copyright © 2026 Alex Fargo.
//

import Foundation
import SwiftUI

// MARK: - AccountDetails

public nonisolated struct AccountDetails: Hashable, Sendable {
  public let userID: String
  public let email: String
  public let name: String
}

// MARK: - Environment Value

public extension EnvironmentValues {
  @Entry var accountDetails: AccountDetails?
}

// MARK: - Preview Helpers

extension AccountDetails {
  static let previewUser = AccountDetails(
    userID: UUID().uuidString,
    email: "test@example.com",
    name: "Test User"
  )
}
