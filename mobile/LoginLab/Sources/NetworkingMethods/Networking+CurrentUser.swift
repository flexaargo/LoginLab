//
//  Networking+CurrentUser.swift
//
//  Copyright © 2026 Alex Fargo.
//

import Foundation

private nonisolated struct CurrentUserResponse: Decodable {
  let user: UserResponse
}

extension NetworkingClient {
  func fetchCurrentUser(accessToken: String) async throws -> UserResponse {
    let response: CurrentUserResponse = try await request(
      path: "/auth/me",
      method: .get,
      additionalHeaders: ["Authorization": "Bearer \(accessToken)"]
    )
    return response.user
  }
}
