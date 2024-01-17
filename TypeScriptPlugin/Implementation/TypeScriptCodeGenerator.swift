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
    let (targetName, headerURL, implementationURL, attributes, files) = try CommandLine.structuredArguments(target: "-t", header: "-h", implementation: "-i", attributes: "-a", files: "-f")
    // 2. Filter out files not containing the exportable attributes.
    let exportableFiles = try await (consume files).filter(attributes: attributes)
    // 3. Parse the Swift files and extract the signature of the exportable global functions.
    let functions = try await (consume exportableFiles).functions(attributes: consume attributes)
    // 4. Generate the TypeScript definition file.
    let definition: String = """
    declare module "swift:*/\(targetName)" {
    \(functions.map { "\texport \($0.typescriptInterface);" }.joined(separator: "\n"))
    }
    """
    // 5. Generate the JavaScript implementation file.
    let implementation: String = functions.map { "export \($0.javascriptImplementation(runner: "runSwiftFunction"))" }.joined(separator: "\n\n")
    // 6. Pipe the generated code to their appropriate output files
    try definition.write(to: consume headerURL, atomically: true, encoding: .utf8)
    try implementation.write(to: consume implementationURL, atomically: true, encoding: .utf8)
  }
}
