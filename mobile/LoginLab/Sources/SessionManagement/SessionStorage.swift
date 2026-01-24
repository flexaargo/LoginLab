//
//  SessionStorage.swift
//
//  Copyright © 2026 Alex Fargo.
//

import Foundation
import Security

/// Manages persistent storage of session data (refresh token and user information).
actor SessionStorage {
  private enum Keys {
    static let refreshToken = "com.loginhub.session.refreshToken"
    static let refreshTokenExpiresAt = "com.loginhub.session.refreshTokenExpiresAt"
    static let userID = "com.loginhub.session.userID"
    static let email = "com.loginhub.session.email"
    static let name = "com.loginhub.session.name"
  }

  private let service: String

  init(service: String = "com.loginhub") {
    self.service = service
  }

  /// Stores the refresh token and its expiration date securely in the Keychain.
  func storeRefreshToken(_ token: String, expiresAt: Date) throws {
    try store(key: Keys.refreshToken, value: token)
    try storeDate(key: Keys.refreshTokenExpiresAt, value: expiresAt)
  }

  /// Retrieves the refresh token from the Keychain.
  func getRefreshToken() throws -> String? {
    return try retrieve(key: Keys.refreshToken)
  }

  /// Retrieves the refresh token expiration date from the Keychain.
  func getRefreshTokenExpiresAt() throws -> Date? {
    return try retrieveDate(key: Keys.refreshTokenExpiresAt)
  }

  /// Checks if the stored refresh token is still valid (not expired).
  func isRefreshTokenValid() throws -> Bool {
    guard let expiresAt = try getRefreshTokenExpiresAt() else {
      return false
    }
    return expiresAt > Date()
  }

  /// Stores user account details.
  func storeAccountDetails(_ accountDetails: AccountDetails) throws {
    try store(key: Keys.userID, value: accountDetails.userID)
    try store(key: Keys.email, value: accountDetails.email)
    try store(key: Keys.name, value: accountDetails.name)
  }

  /// Retrieves stored account details.
  func getAccountDetails() throws -> AccountDetails? {
    guard
      let userID = try retrieve(key: Keys.userID),
      let email = try retrieve(key: Keys.email),
      let name = try retrieve(key: Keys.name)
    else {
      return nil
    }

    return AccountDetails(userID: userID, email: email, name: name)
  }

  /// Clears all stored session data.
  func clear() throws {
    try delete(key: Keys.refreshToken)
    try delete(key: Keys.refreshTokenExpiresAt)
    try delete(key: Keys.userID)
    try delete(key: Keys.email)
    try delete(key: Keys.name)
  }

  // MARK: - Keychain Helpers

  private func storeDate(key: String, value: Date) throws {
    let timestamp = value.timeIntervalSince1970
    var timestampData = timestamp
    let data = Data(bytes: &timestampData, count: MemoryLayout<Double>.size)

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
      kSecValueData as String: data,
    ]

    // Delete existing item first
    SecItemDelete(query as CFDictionary)

    // Add new item
    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
      throw SessionStorageError.storeFailed(status)
    }
  }

  private func retrieveDate(key: String) throws -> Date? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    guard status == errSecSuccess else {
      if status == errSecItemNotFound {
        return nil
      }
      throw SessionStorageError.retrieveFailed(status)
    }

    guard let data = result as? Data,
          data.count == MemoryLayout<Double>.size
    else {
      return nil
    }

    let timestamp = data.withUnsafeBytes { $0.load(as: Double.self) }
    return Date(timeIntervalSince1970: timestamp)
  }

  private func store(key: String, value: String) throws {
    let data = value.data(using: .utf8)!
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
      kSecValueData as String: data,
    ]

    // Delete existing item first
    SecItemDelete(query as CFDictionary)

    // Add new item
    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
      throw SessionStorageError.storeFailed(status)
    }
  }

  private func retrieve(key: String) throws -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    guard status == errSecSuccess else {
      if status == errSecItemNotFound {
        return nil
      }
      throw SessionStorageError.retrieveFailed(status)
    }

    guard let data = result as? Data,
          let value = String(data: data, encoding: .utf8)
    else {
      return nil
    }

    return value
  }

  private func delete(key: String) throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
    ]

    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw SessionStorageError.deleteFailed(status)
    }
  }
}

enum SessionStorageError: Error {
  case storeFailed(OSStatus)
  case retrieveFailed(OSStatus)
  case deleteFailed(OSStatus)

  var localizedDescription: String {
    switch self {
    case let .storeFailed(status):
      return "Failed to store item in Keychain: \(status)"
    case let .retrieveFailed(status):
      return "Failed to retrieve item from Keychain: \(status)"
    case let .deleteFailed(status):
      return "Failed to delete item from Keychain: \(status)"
    }
  }
}
