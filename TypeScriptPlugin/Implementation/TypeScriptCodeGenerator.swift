// Copyright © 2024 Raycast. All rights reserved.

import Foundation

@main struct TypeScriptCodeGenerator {
  static func main() async throws {
    let (target, attributes, files) = try CommandLine.structuredArguments(flags: "-t", "-a", "-f")

    let functions = try await files
      .contains(attributes: attributes)
      .functions(attributes: attributes)

    print("""
    // @raycast Interface Generation (\(target))

    declare module "swift:*/SwiftPackage" {
    \(functions.map { "\texport \($0.declaration)" }.joined(separator: "\n"))
    }

    // @raycast Implementation Generation (\(target))

    """)

    #warning("Implementation here")
  }
}
