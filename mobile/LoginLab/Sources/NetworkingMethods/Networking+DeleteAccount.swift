//
//  Networking+DeleteAccount.swift
//
//  Copyright © 2026 Alex Fargo.
//

import Foundation

private nonisolated struct DeleteAccountRequest: Encodable {
  let identityToken: String
  let authorizationCode: String
  let nonce: String
}

private nonisolated struct DeleteAccountResponse: Decodable {
  let success: Bool
}

extension NetworkingClient {
  /// Deletes the user's account. Requires a valid access token and fresh Apple Sign In credentials.
  /// The backend revokes the Apple token then deletes user data.
  func deleteAccount(
    accessToken: String,
    identityToken: String,
    authorizationCode: String,
    nonce: String
  ) async throws {
    let requestBody = DeleteAccountRequest(
      identityToken: identityToken,
      authorizationCode: authorizationCode,
      nonce: nonce
    )

    let _: DeleteAccountResponse = try await request(
      path: "/auth/delete-account",
      method: .post,
      body: requestBody,
      additionalHeaders: ["Authorization": "Bearer \(accessToken)"]
    )
  }
}
