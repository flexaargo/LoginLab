//
//  Networking+SignOut.swift
//
//  Copyright © 2026 Alex Fargo.
//

import Foundation

private nonisolated struct SignOutRequest: Encodable {
  let refreshToken: String
}

extension NetworkingClient {
  func signOut(refreshToken: String) async throws {
    let requestBody = SignOutRequest(refreshToken: refreshToken)

    try await request(
      path: "/auth/signout",
      method: .post,
      body: requestBody
    )
  }
}
