//
//  SessionManagerError.swift
//
//  Copyright © 2026 Alex Fargo.
//

import Foundation

enum SessionManagerError: LocalizedError {
  case notAuthenticated
  case missingAppleCredentials

  var errorDescription: String? {
    switch self {
    case .notAuthenticated:
      "Not authenticated."
    case .missingAppleCredentials:
      "Apple Sign In did not return required credentials."
    }
  }
}
