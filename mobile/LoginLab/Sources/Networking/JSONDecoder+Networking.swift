//
//  JSONDecoder+Networking.swift
//
//  Copyright © 2026 Alex Fargo.
//

import Foundation

extension JSONDecoder {
  /// A JSON decoder configured to decode dates from epoch seconds (Unix timestamps).
  static let epochSeconds: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .secondsSince1970
    return decoder
  }()
}
