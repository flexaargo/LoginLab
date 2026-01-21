//
//  NetworkingRequest.swift
//
//  Copyright © 2026 Alex Fargo.
//

import Foundation

enum HTTPMethod: String {
  case get
  case post
  case put
  case delete
}

enum HTTPScheme: String {
  case http
  case https
}

struct NetworkingRequest {
  var host: String
  var port: Int
  var scheme: HTTPScheme
  var path: String
  var method: HTTPMethod
  var body: Data?
  var headers: [String: String]

  func buildURL() -> URL? {
    let components = buildURLComponents()
    return components.url
  }

  func buildURLComponents() -> URLComponents {
    var components = URLComponents()
    components.scheme = scheme.rawValue
    components.host = host
    components.port = port
    components.path = path
    return components
  }
}
