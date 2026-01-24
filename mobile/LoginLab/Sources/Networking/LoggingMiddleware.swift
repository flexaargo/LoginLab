//
//  LoggingMiddleware.swift
//
//  Copyright © 2026 Alex Fargo.
//

import Foundation

/// Middleware that logs request and response details for debugging.
public struct LoggingMiddleware: URLRequestAwareMiddleware {
  /// Whether to log request details.
  public let logRequests: Bool
  /// Whether to log response details.
  public let logResponses: Bool
  /// Whether to log errors.
  public let logErrors: Bool
  /// Whether to log request/response bodies.
  public let logBodies: Bool

  /// Creates a logging middleware with customizable logging options.
  /// - Parameters:
  ///   - logRequests: Whether to log request details (default: true)
  ///   - logResponses: Whether to log response details (default: true)
  ///   - logErrors: Whether to log errors (default: true)
  ///   - logBodies: Whether to log request/response bodies (default: true)
  public init(
    logRequests: Bool = true,
    logResponses: Bool = true,
    logErrors: Bool = true,
    logBodies: Bool = true
  ) {
    self.logRequests = logRequests
    self.logResponses = logResponses
    self.logErrors = logErrors
    self.logBodies = logBodies
  }

  public func prepare(_ request: inout NetworkingRequest) async throws {
    // Logging happens in onURLRequestReady for full URLRequest details
  }

  public func onURLRequestReady(_ urlRequest: URLRequest) async throws {
    guard logRequests else { return }

    print("🔍 [Request] \(urlRequest.httpMethod ?? "Unknown Method") \(urlRequest.url?.absoluteString ?? "Unknown URL")")
    if let headers = urlRequest.allHTTPHeaderFields, !headers.isEmpty {
      print("🔍 [Request Headers]")
      for (key, value) in headers.sorted(by: { $0.key < $1.key }) {
        print("🔍   \(key): \(value)")
      }
    }
    if logBodies {
      if let body = urlRequest.httpBody, !body.isEmpty {
        print("🔍 [Request Body]")
        print(Self.prettyPrintBody(body))
      } else {
        print("🔍 [Request Body] Empty body")
      }
    }
  }

  public func onResponse(_ request: NetworkingRequest, response: HTTPURLResponse, data: Data) async throws {
    guard logResponses else { return }

    print("✅ [Response] \(response.statusCode) \(HTTPURLResponse.localString(forStatusCode: response.statusCode))")
    if let url = response.url {
      print("✅ [Response URL] \(url.absoluteString)")
    }
    if logBodies, !data.isEmpty {
      print("✅ [Response Body]")
      print(Self.prettyPrintBody(data))
    }
  }

  /// Pretty-prints JSON data when possible; otherwise returns raw UTF-8 string.
  /// Long bodies are truncated with a clear indicator.
  /// Each line is indented for clear nesting under the section header.
  private static func prettyPrintBody(_ data: Data, maxLength: Int = 2000) -> String {
    let truncated: Data
    let suffix: String
    if data.count > maxLength {
      truncated = data.prefix(maxLength)
      suffix = "\n   ... (\(data.count - maxLength) bytes truncated)"
    } else {
      truncated = data
      suffix = ""
    }

    let raw: String
    guard let json = try? JSONSerialization.jsonObject(with: truncated),
          let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
          let pretty = String(data: prettyData, encoding: .utf8)
    else {
      raw = (String(data: truncated, encoding: .utf8) ?? "<invalid UTF-8>") + suffix
      return raw.split(separator: "\n").map { "   \($0)" }.joined(separator: "\n")
    }

    let indented = pretty.split(separator: "\n").map { "   \($0)" }.joined(separator: "\n")
    return indented + suffix
  }

  public func onError(_ request: NetworkingRequest, error: Error) async {
    guard logErrors else { return }

    print("❌ [Error] \(error.localizedDescription)")
    if let urlError = error as? URLError {
      print("❌ [URLError] Code: \(urlError.code.rawValue), Description: \(urlError.localizedDescription)")
    }
  }
}

extension HTTPURLResponse {
  /// Returns a localized string for the HTTP status code.
  static func localString(forStatusCode code: Int) -> String {
    HTTPURLResponse.localizedString(forStatusCode: code)
  }
}
