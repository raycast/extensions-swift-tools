// Copyright © 2024 Raycast. All rights reserved.

import PackagePlugin

/// Build tool generating the `@main` structure for an executable Swift target exporting functions to use in Raycast extensions.
@main struct SwiftCodeInterface: BuildToolPlugin {
  func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
    // 1. Verify the SPM target is a Swift target.
    guard let target = target as? SwiftSourceModuleTarget else {
      Diagnostics.error("\(target.name) is not a Swift target")
      return []
    }
    // 2. Verify the Swift target is executables (any thing else such as libraries or plugins aren't supported).
    guard case .executable = target.kind else {
      Diagnostics.error("\(target.name) is not a executable target")
      return []
    }
    // 3. Verify the executable target doesn't contain a `main.swift` file.
    let unsupportedFile = "main.swift"
    guard !target.sourceFiles.contains(where: { $0.type == .source && $0.path.lastComponent.lowercased() == unsupportedFile }) else {
      Diagnostics.error("\(target.name) executable target cannot define a \(unsupportedFile) file")
      return []
    }
    // 4. Specify the path to the Swift file containing the @main structure (in the build folder)
    let generatedEntryType = "_RayMain"
    let generatedFile = "\(generatedEntryType).swift"
    let generatedPath = context.pluginWorkDirectory.appending(subpath: generatedFile)
    // 5. Launch the Swift code generator for the target executing the build plugin.
    return [
      .buildCommand(
        displayName: "Generating \(generatedFile)",
        executable: try context.tool(named: "SwiftCodeGenerator").path,
        arguments: ["-o", generatedPath.string, "-m", target.moduleName, "-t", generatedEntryType],
        outputFiles: [generatedPath]
      )
    ]
  }
}
