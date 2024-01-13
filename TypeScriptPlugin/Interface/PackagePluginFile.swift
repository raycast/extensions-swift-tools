// Copyright © 2024 Raycast. All rights reserved.

import Foundation
import PackagePlugin

extension PackagePlugin.File {
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
