// Copyright © 2024 Raycast. All rights reserved.

import Foundation

extension StringProtocol {
  var fileURL: URL? {
    let str: String = (self as? String) ?? String(self)
    guard let url = URL(string: str) else { return .none }

    switch url.scheme {
    case "file": return url
    case .some: return .none
    case .none: break
    }

    return if #available(macOS 13, *) {
      URL(filePath: str)
    } else {
      URL(fileURLWithPath: str)
    }
  }
}

extension Sequence where Element == URL {
  /// Lazily filter out files not containing any of the given `attributes`.
  func filter(attributes: [String]) async throws -> [URL] {
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
