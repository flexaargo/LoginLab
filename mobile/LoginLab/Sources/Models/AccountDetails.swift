//
//  AccountDetails.swift
//
//  Copyright © 2026 Alex Fargo.
//

import Foundation
import SwiftUI

public nonisolated struct AccountDetails: Hashable, Sendable {
  public let userID: String
  public let email: String
  public let name: String
}

public extension EnvironmentValues {
  @Entry var accountDetails: AccountDetails?
}
