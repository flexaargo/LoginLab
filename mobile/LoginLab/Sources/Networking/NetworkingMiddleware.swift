//
//  NetworkingMiddleware.swift
//
//  Copyright © 2026 Alex Fargo.
//

import Foundation

/// A middleware that can intercept and modify network requests and responses.
/// Middleware are executed in order before the request is sent and after the response is received.
public protocol NetworkingMiddleware: Sendable {
  /// Called before a request is sent. Can modify the request.
  /// - Parameter request: The networking request that will be sent
  /// - Returns: A modified request (or the original if no changes are needed)
  func prepare(_ request: inout NetworkingRequest) async throws

  /// Called after a successful response is received.
  /// - Parameters:
  ///   - request: The original request that was sent
  ///   - response: The HTTP response
  ///   - data: The response data
  func onResponse(_ request: NetworkingRequest, response: HTTPURLResponse, data: Data) async throws

  /// Called when an error occurs during the request.
  /// - Parameters:
  ///   - request: The original request that was sent
  ///   - error: The error that occurred
  func onError(_ request: NetworkingRequest, error: Error) async
}

/// Optional protocol for middleware that want to access the full URLRequest before it's sent.
/// This is useful for logging complete request details including the full URL.
public protocol URLRequestAwareMiddleware: NetworkingMiddleware {
  /// Called after the URLRequest is constructed but before it's sent.
  /// - Parameter urlRequest: The complete URLRequest that will be sent
  func onURLRequestReady(_ urlRequest: URLRequest) async throws
}

/// Default implementations for optional middleware methods.
public extension NetworkingMiddleware {
  func prepare(_ request: inout NetworkingRequest) async throws {
    // Default: no modification
  }

  func onResponse(_ request: NetworkingRequest, response: HTTPURLResponse, data: Data) async throws {
    // Default: no action
  }

  func onError(_ request: NetworkingRequest, error: Error) async {
    // Default: no action
  }
}
