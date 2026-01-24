//
//  NetworkingClient.swift
//
//  Copyright © 2026 Alex Fargo.
//

import Foundation
import UIKit

/// A networking client for making HTTP requests.
/// This is an actor to provide thread-safety and protect future mutable state (interceptors, token refresh, caching, etc.)
actor NetworkingClient {
  /// The base URL for all requests.
  private let baseURL: URL

  /// Middleware to apply to requests and responses.
  private var middleware: [any NetworkingMiddleware] = []

  /// Empty response type for requests that don't return a body.
  private struct EmptyResponse: Decodable {}

  /// Empty body type for requests that don't send a body.
  private struct EmptyBody: Encodable {}

  /// Initializes a client with a base URL.
  init(baseURL: URL) {
    self.baseURL = baseURL
  }

  /// Initializes a client with host, port, and scheme components.
  /// - Note: This initializer will crash if the URL cannot be constructed, which should never happen with valid inputs.
  init(
    host: String,
    port: Int,
    scheme: HTTPScheme
  ) {
    var components = URLComponents()
    components.scheme = scheme.rawValue
    components.host = host
    components.port = port

    // This should never fail with valid inputs, but we guard for safety
    guard let url = components.url else {
      fatalError("Failed to create base URL from components: scheme=\(scheme.rawValue), host=\(host), port=\(port)")
    }
    self.baseURL = url
  }

  /// Adds middleware to the client. Middleware are executed in the order they are added.
  /// - Parameter middleware: The middleware to add
  func addMiddleware(_ middleware: any NetworkingMiddleware) {
    self.middleware.append(middleware)
  }

  /// Removes all middleware from the client.
  func clearMiddleware() {
    middleware.removeAll()
  }

  /// The default JSON decoder for responses.
  private static let defaultDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    return decoder
  }()

  /// Performs a network request and decodes the response.
  /// This is the core method that extensions can build upon.
  /// The response type is inferred from the return type.
  /// - Parameter networkingRequest: The networking request to perform
  /// - Returns: The decoded response of the inferred type
  func request<T: Decodable>(
    _ networkingRequest: NetworkingRequest
  ) async throws -> T {
    // Merge default headers into the request
    var request = networkingRequest
    request.headers["X-Device-Name"] = await UIDevice.current.name

    // Apply middleware to prepare/modify the request
    for middleware in middleware {
      try await middleware.prepare(&request)
    }

    let urlRequest = try request.toURLRequest(baseURL: baseURL)

    // Notify middleware that URLRequest is ready (for logging full request details)
    for middleware in middleware {
      if let urlRequestAware = middleware as? any URLRequestAwareMiddleware {
        try await urlRequestAware.onURLRequestReady(urlRequest)
      }
    }

    do {
      let (data, response) = try await URLSession.shared.data(for: urlRequest)

      guard let httpResponse = response as? HTTPURLResponse else {
        let error = URLError(.badServerResponse)
        // Notify middleware of error
        for middleware in middleware {
          await middleware.onError(request, error: error)
        }
        throw error
      }

      guard (200 ... 299).contains(httpResponse.statusCode) else {
        let error = URLError(.badServerResponse)
        // Notify middleware of error
        for middleware in middleware {
          await middleware.onError(request, error: error)
        }
        throw error
      }

      // Notify middleware of successful response
      for middleware in middleware {
        try await middleware.onResponse(request, response: httpResponse, data: data)
      }

      let decoder = request.decoder ?? Self.defaultDecoder
      return try decoder.decode(T.self, from: data)
    } catch {
      // Notify middleware of error
      for middleware in middleware {
        await middleware.onError(request, error: error)
      }
      throw error
    }
  }

  /// Performs a network request without expecting a response body.
  func request(_ networkingRequest: NetworkingRequest) async throws {
    let _: EmptyResponse = try await request(networkingRequest)
  }

  /// Convenience method for requests without a body.
  /// The response type is inferred from the return type.
  /// - Parameters:
  ///   - path: The API endpoint path
  ///   - method: The HTTP method
  ///   - queryItems: Optional query parameters
  ///   - additionalHeaders: Any additional headers to include
  ///   - decoder: Optional JSON decoder for the response (defaults to standard decoder)
  /// - Returns: The decoded response of the inferred type
  func request<T: Decodable>(
    path: String,
    method: HTTPMethod,
    queryItems: [URLQueryItem]? = nil,
    additionalHeaders: [String: String] = [:],
    decoder: JSONDecoder? = nil
  ) async throws -> T {
    let request = NetworkingRequest(
      path: path,
      method: method,
      headers: additionalHeaders,
      queryItems: queryItems,
      decoder: decoder
    )

    return try await self.request(request)
  }

  /// Convenience method for requests with an encodable body.
  /// The response type is inferred from the return type.
  /// - Parameters:
  ///   - path: The API endpoint path
  ///   - method: The HTTP method
  ///   - body: An encodable request body
  ///   - queryItems: Optional query parameters
  ///   - additionalHeaders: Any additional headers to include
  ///   - decoder: Optional JSON decoder for the response (defaults to standard decoder)
  /// - Returns: The decoded response of the inferred type
  func request<T: Decodable, B: Encodable>(
    path: String,
    method: HTTPMethod,
    body: B,
    queryItems: [URLQueryItem]? = nil,
    additionalHeaders: [String: String] = [:],
    decoder: JSONDecoder? = nil
  ) async throws -> T {
    let request = try NetworkingRequest(
      path: path,
      method: method,
      body: body,
      headers: additionalHeaders,
      queryItems: queryItems,
      decoder: decoder
    )

    return try await self.request(request)
  }

  /// Convenience method for requests without a response body and without a request body.
  func request(
    path: String,
    method: HTTPMethod,
    queryItems: [URLQueryItem]? = nil,
    additionalHeaders: [String: String] = [:]
  ) async throws {
    let _: EmptyResponse = try await request(
      path: path,
      method: method,
      queryItems: queryItems,
      additionalHeaders: additionalHeaders
    )
  }

  /// Convenience method for requests without a response body but with a request body.
  func request<B: Encodable>(
    path: String,
    method: HTTPMethod,
    body: B,
    queryItems: [URLQueryItem]? = nil,
    additionalHeaders: [String: String] = [:]
  ) async throws {
    let _: EmptyResponse = try await request(
      path: path,
      method: method,
      body: body,
      queryItems: queryItems,
      additionalHeaders: additionalHeaders
    )
  }
}
