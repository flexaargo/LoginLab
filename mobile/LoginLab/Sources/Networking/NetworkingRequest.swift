//
//  NetworkingRequest.swift
//
//  Copyright © 2026 Alex Fargo.
//

import Foundation

nonisolated struct NetworkingRequest: Sendable {
  var path: String
  var method: HTTPMethod
  var body: Data?
  var headers: [String: String]
  var queryItems: [URLQueryItem]?

  /// Creates a request without a body.
  init(
    path: String,
    method: HTTPMethod,
    headers: [String: String] = [:],
    queryItems: [URLQueryItem]? = nil
  ) {
    self.path = path
    self.method = method
    self.body = nil
    self.headers = headers
    self.queryItems = queryItems
  }

  /// Creates a request with an encodable body.
  /// - Parameters:
  ///   - path: The API endpoint path
  ///   - method: The HTTP method
  ///   - body: An encodable request body (will be JSON encoded)
  ///   - headers: Custom headers
  ///   - queryItems: Optional query parameters
  /// - Throws: Encoding errors if the body cannot be encoded
  init<B: Encodable>(
    path: String,
    method: HTTPMethod,
    body: B,
    headers: [String: String] = [:],
    queryItems: [URLQueryItem]? = nil
  ) throws {
    self.path = path
    self.method = method
    self.body = try JSONEncoder().encode(body)
    self.headers = headers
    self.queryItems = queryItems
  }

  /// Creates a request with a raw Data body.
  init(
    path: String,
    method: HTTPMethod,
    body: Data? = nil,
    headers: [String: String] = [:],
    queryItems: [URLQueryItem]? = nil
  ) {
    self.path = path
    self.method = method
    self.body = body
    self.headers = headers
    self.queryItems = queryItems
  }

  /// Converts the request to a `URLRequest` ready for use with `URLSession`.
  /// - Parameters:
  ///   - baseURL: The base URL (scheme, host, port) to combine with the request path
  /// - Throws: `URLError.badURL` if the URL cannot be constructed
  func toURLRequest(baseURL: URL) throws -> URLRequest {
    guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true) else {
      throw URLError(.badURL)
    }

    // Append path (handling leading/trailing slashes)
    let normalizedPath = path.hasPrefix("/") ? path : "/\(path)"
    components.path = (components.path + normalizedPath).replacingOccurrences(of: "//", with: "/")
    components.queryItems = queryItems?.isEmpty == false ? queryItems : nil

    guard let url = components.url else {
      throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue.uppercased()
    request.httpBody = body

    // Add all custom headers first
    for (key, value) in headers {
      request.setValue(value, forHTTPHeaderField: key)
    }

    // Add Content-Type header if body exists and no Content-Type is already set
    if body != nil {
      let hasContentType = request.value(forHTTPHeaderField: "Content-Type") != nil
      if !hasContentType {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      }
    }

    return request
  }
}
