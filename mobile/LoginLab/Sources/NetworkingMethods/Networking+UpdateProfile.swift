//
//  Networking+UpdateProfile.swift
//
//  Copyright © 2026 Alex Fargo.
//

import Foundation

private nonisolated struct UpdateProfileRequest: Encodable {
  let fullName: String?
  let displayName: String?
  let imageBase64: String?
  let imageMimeType: String?
}

private nonisolated struct UpdateProfileResponse: Decodable {
  let user: UserResponse
}

extension NetworkingClient {
  /// Updates the user's profile. All parameters are optional; only provided values are updated.
  /// - Parameters:
  ///   - accessToken: A valid access token.
  ///   - fullName: The user's full name (optional).
  ///   - displayName: The user's display name (optional).
  ///   - imageData: Binary image data (optional). When provided with mimeType, encodes as base64.
  ///   - mimeType: The MIME type for imageData, e.g. image/png (required when imageData is provided).
  /// - Returns: The updated user response.
  func updateProfile(
    accessToken: String,
    fullName: String? = nil,
    displayName: String? = nil,
    imageData: Data? = nil,
    mimeType: String? = nil
  ) async throws -> UserResponse {
    let imageBase64: String?
    let imageMimeType: String?
    if let imageData, let mimeType {
      imageBase64 = imageData.base64EncodedString()
      imageMimeType = mimeType
    } else {
      imageBase64 = nil
      imageMimeType = nil
    }

    let requestBody = UpdateProfileRequest(
      fullName: fullName,
      displayName: displayName,
      imageBase64: imageBase64,
      imageMimeType: imageMimeType
    )

    let response: UpdateProfileResponse = try await request(
      path: "/auth/profile",
      method: .patch,
      body: requestBody,
      additionalHeaders: ["Authorization": "Bearer \(accessToken)"]
    )

    return response.user
  }
}
