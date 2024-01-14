// Copyright © 2024 Raycast. All rights reserved.

import Foundation

/// Command-Line tool generating the TS code which can call Swift code from a Raycast extension.
///
/// This command is customizable by using the following _short_ options:
/// - `-t name` (required) specifies the Swift target that this code references.
/// - `-a name1 name2` (at least one required) specifies the Swift attributes marking a Swift global function as exportable (e.g. `@raycast`).
/// - `-f file1 file2` (at least one required) specifies all Swift files containing one of the previously defined Swift attributes.
@main struct TypeScriptCodeGenerator {
  static func main() async throws {
    // 1. Extract all flags/options passed to this Command-Line tool.
    let (target, attributes, files) = try CommandLine.structuredArguments(flags: "-t", "-a", "-f")
    // 2. Filter out files not containing the exportable attributes.
    let exportableFiles = try await files.filter(attributes: attributes)
    // 3. Parse the Swift files and extract the signature of the exportable global functions.
    let functions = try await (consume exportableFiles).functions(attributes: consume attributes)
    // 5. Passed in stdout the generated interface and implementation TS content.
    print(tsFile(target: consume target, functions: consume functions, swiftRunner: "runSwiftFunction"))
  }
}

private func tsFile(target: String, functions: [ExportableFunction], swiftRunner functionName: String) -> String {
  """
  // @raycast Generated Interface (\(target))

  declare module "swift:*/SwiftPackage" {
  \(functions.map { "\texport \($0.interface);" }.joined(separator: "\n"))
  }

  // @raycast Generated Implementation (\(target))

  \(functions.map { $0.implementation(runner: functionName) }.joined(separator: "\n\n"))

  """
}
