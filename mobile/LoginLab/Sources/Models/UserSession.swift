//
//  UserSession.swift
//
//  Copyright © 2026 Alex Fargo.
//

import Foundation
import SwiftUI

nonisolated public struct UserSession: Hashable, Sendable {
  public let accountDetails: AccountDetails
  public let accessToken: String
  public let refreshToken: String
}

public extension EnvironmentValues {
  @Entry var userSession: UserSession?
}
