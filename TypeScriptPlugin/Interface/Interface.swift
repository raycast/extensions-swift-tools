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
    let generator = try context.tool(named: "TypeScriptCodeGenerator").url
    // Define the attributes used to mark functions as _exportable_
    let attributes: [String] = ["@raycast"]

    var fileURLs: Set<URL> = []
    // Enumerate all Swift files in the target.
    for file in target.sourceFiles(withSuffix: "swift") {
      // Select those files containing any of the specified exportable attributes.
      guard case .source = file.type, !fileURLs.contains(file.url),
            try await file.contains(attributes: attributes) else { continue }
      fileURLs.insert(file.url)
    }

    guard !fileURLs.isEmpty else {
      Diagnostics.warning("Target '\(target.name) had no file with exported attributes: \(attributes.joined(separator: " or "))")
      return []
    }

    // Generate the header and implementation file names.
    let headerURL = context.pluginWorkDirectoryURL.appendingPathComponent("raycast.d.ts")
    let implementationURL = context.pluginWorkDirectoryURL.appendingPathComponent("raycast.js")

    return [
      .buildCommand(
        displayName: "Generating d.ts and js files",
        executable: generator,
        arguments: ["-h", headerURL.path, "-i", implementationURL.path, "-a"] + attributes + ["-f"] + fileURLs.map(\.path),
        outputFiles: [headerURL, implementationURL]
      )
    ]
  }
}
