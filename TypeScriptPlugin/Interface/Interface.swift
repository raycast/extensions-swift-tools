// Copyright © 2024 Raycast. All rights reserved.

import PackagePlugin
import Foundation

/// Build tool generating the `d.ts` interface and TypeScript implementation file for a Swift target intended to be used in Raycast extensions.
@main struct TypeScriptCodeInterface: BuildToolPlugin {
  func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
    // Verify the SPM target is a Swift target.
    guard let target = target as? SwiftSourceModuleTarget else {
      Diagnostics.error("\(target.name) is not a Swift target")
      return []
    }
    // Verify the Swift target is executables (any thing else such as libraries or plugins aren't supported).
    guard case .executable = target.kind else {
      Diagnostics.error("\(target.name) is not a executable target")
      return []
    }
    // Retrieve the tool used to generate the TS definition and implementation.
    let generator = try context.tool(named: "TypeScriptCodeGenerator").path
    // Define the attributes used to mark functions as _exportable_
    let attributes: [String] = ["@raycast"]

    var paths: Set<Path> = []
    // Enumerate all Swift files in the target.
    for file in target.sourceFiles(withSuffix: "swift") {
      // Select those files containing any of the specified exportable attributes.
      guard case .source = file.type, !paths.contains(file.path),
            try await file.contains(attributes: attributes) else { continue }
      paths.insert(file.path)
    }

    guard !paths.isEmpty else {
      Diagnostics.warning("Target '\(target.name) had no file with exported attributes: \(attributes.joined(separator: " or "))")
      return []
    }

    // Generate the header and implementation file names.
    let headerPath = context.pluginWorkDirectory.appending(subpath: "raycast.d.ts")
    let implementationPath = context.pluginWorkDirectory.appending(subpath: "raycast.js")

    return [
      .buildCommand(
        displayName: "Generating d.ts and js files",
        executable: generator,
        arguments: ["-t", target.name, "-h", headerPath.string, "-i", implementationPath.string, "-a"] + attributes + ["-f"] + paths.map(\.string),
        outputFiles: [headerPath, implementationPath]
      )
    ]
  }
}
