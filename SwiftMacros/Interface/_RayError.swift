// Copyright © 2024 Raycast. All rights reserved.

import Foundation

public extension _Ray {
  /// Errors generated within a macro expansion.
  enum MacroError: Swift.Error {
    case invalidArguments
  }

  struct DecodingArgumentError<A, E>: Swift.Error where E: Swift.Error {
    public let name: String
    public let position: Int
    public let data: Data
    public let underlying: E

    public init(name: String, position: Int, type: A.Type = A.self, data: Data, underlying: E) {
      self.name = name
      self.position = position
      self.data = data
      self.underlying = underlying
    }

    public var localizedDescription: String {
      """
      Failed to decode argument at position '\(position)' with identifier '\(name)' of expected type '\(A.self)' with received content '\(String(decoding: data, as: UTF8.self))'
      Underlying decoding error: \(underlying.localizedDescription)
      """
    }
  }
}
