// Copyright © 2024 Raycast. All rights reserved.

import Foundation
import PackagePlugin

extension PackagePlugin.File {
  /// Look for the existence of any of the given `attributes` in the receiving file.
  /// - note: This is a _lazy_ function, meaning that as soon as an attribute existence is identified, no more lines in the receiving file will get read.
  func contains(attributes: [String]) async throws -> Bool {
    for try await line in path.url.lines {
      for attribute in attributes where line.contains(attribute) {
        return true
      }
    }
    return false
  }
}

extension PackagePlugin.Path {
  var url: URL {
    if #available(macOS 13, *) {
      URL(filePath: string)
    } else {
      URL(fileURLWithPath: string)
    }
  }
}
