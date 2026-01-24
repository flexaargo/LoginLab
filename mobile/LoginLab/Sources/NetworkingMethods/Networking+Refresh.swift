//
//  Networking+Refresh.swift
//
//  Copyright © 2026 Alex Fargo.
//

import Foundation

private nonisolated struct RefreshTokensRequest: Encodable {
  let refreshToken: String
}

nonisolated struct RefreshTokensResponse: Decodable {
  let accessToken: String
  let accessTokenExpiresAt: Date
  let refreshToken: String
  let refreshTokenExpiresAt: Date
}

extension NetworkingClient {
  func refreshTokens(refreshToken: String) async throws -> RefreshTokensResponse {
    let requestBody = RefreshTokensRequest(refreshToken: refreshToken)

    let response: RefreshTokensResponse = try await request(
      path: "/auth/refresh",
      method: .post,
      body: requestBody,
      decoder: .epochSeconds
    )
    return response
  }
}
