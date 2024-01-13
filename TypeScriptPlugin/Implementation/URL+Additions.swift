// Copyright © 2024 Raycast. All rights reserved.

import Foundation

extension Sequence where Element == URL {
  func contains(attributes: [String]) async throws -> [URL] {
    precondition(!attributes.isEmpty)
    var result: [URL] = []

    let targets = attributes.map { (content: $0, count: $0.count) }
    for fileURL in self {
      for try await line in fileURL.lines where !line.isEmpty {
        guard case .some = line.rangeOf(attributes: targets) else { continue }
        result.append(fileURL)
        break
      }
    }

    return result
  }
}

// MARK: -

private extension StringProtocol {
  func rangeOf(attributes: [(content: String, count: Int)]) -> Range<String.Index>? {
    let endIndex = endIndex
    var i = startIndex

    repeat {
      for (attribute, count) in attributes {
        guard self[i...].hasPrefix(attribute) else { continue }
        return i..<self.index(i, offsetBy: count)
      }
      i = index(after: i)
    } while i < endIndex

    return .none
  }
}
