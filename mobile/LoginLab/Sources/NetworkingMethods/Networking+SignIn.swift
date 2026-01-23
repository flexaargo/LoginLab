//
//  Networking+SignIn.swift
//
//  Copyright © 2026 Alex Fargo.
//

import Foundation

private nonisolated struct SignInRequest: Encodable {
  let identityToken: String
  let authorizationCode: String
  let nonce: String
  let fullName: String?
  let email: String?
}

nonisolated struct SignInResponse: Decodable {
  let user: UserResponse
  let accessToken: String
  let refreshToken: String
}

nonisolated struct UserResponse: Decodable {
  let id: String
  let fullName: String
  let email: String
  let displayName: String
}

extension NetworkingClient {
  func signIn(
    identityToken: String,
    authorizationCode: String,
    nonce: String,
    fullName: String?,
    email: String?
  ) async throws -> SignInResponse {
    let requestBody = SignInRequest(
      identityToken: identityToken,
      authorizationCode: authorizationCode,
      nonce: nonce,
      fullName: fullName,
      email: email
    )

    let response: SignInResponse = try await request(
      path: "/auth/signin",
      method: .post,
      body: requestBody
    )

    return response
  }
}
