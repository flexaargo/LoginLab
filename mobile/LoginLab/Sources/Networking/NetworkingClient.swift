//
//  NetworkingClient.swift
//
//  Copyright © 2026 Alex Fargo.
//

import Foundation
import UIKit

struct NetworkingClient {
  /// Allows connetion to local development server.
  private let host = "Alexs-MacBook-Pro.local"
  private let port = 3000

  func signIn(
    identityToken: String,
    authorizationCode: String,
    nonce: String,
    fullName: String?,
    email: String?
  ) async throws {
    let body = [
      "identityToken": identityToken,
      "authorizationCode": authorizationCode,
      "nonce": nonce,
      "fullName": fullName,
      "email": email,
    ].compactMapValues { $0 }

    let bodyData = try JSONSerialization.data(withJSONObject: body)

    var headers: [String: String] = [
      "Content-Type": "application/json",
    ]
    let deviceName = UIDevice.current.name
    headers["X-Device-Name"] = deviceName

    let request = NetworkingRequest(
      host: host,
      port: port,
      scheme: .http,
      path: "/auth/signin",
      method: .post,
      body: bodyData,
      headers: headers
    )

    guard let url = request.buildURL() else { return }

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = request.method.rawValue.uppercased()
    urlRequest.httpBody = request.body
    urlRequest.allHTTPHeaderFields = request.headers

    let (data, res) = try await URLSession.shared.data(for: urlRequest)

    guard let httpResponse = res as? HTTPURLResponse, 200 ... 299 ~= httpResponse.statusCode else {
      throw URLError(.badServerResponse)
    }
    let response = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    print("Response: \(response, default: "None")")
  }
}
