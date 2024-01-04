// Copyright © 2024 Raycast. All rights reserved.

import PackagePlugin

@main struct SwiftCodeInterface: BuildToolPlugin {
  func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
    guard let target = target as? SwiftSourceModuleTarget else {
      Diagnostics.error("\(target.name) is not a Swift target")
      return []
    }

    guard case .executable = target.kind else {
      Diagnostics.error("\(target.name) is not a executable target")
      return []
    }

    let unsupportedFile = "main.swift"
    guard !target.sourceFiles.contains(where: { $0.type == .source && $0.path.lastComponent.lowercased() == unsupportedFile }) else {
      Diagnostics.error("\(target.name) target cannot define a \(unsupportedFile) file")
      return []
    }

    let generatorName = "SwiftCodeGenerator"
    let generatedFile = "_RayMain.swift"
    let generatedPath = context.pluginWorkDirectory.appending(subpath: generatedFile)
    let generatedEntryType = "_RayMain"

    let executablePath: Path
    do {
      executablePath = try context.tool(named: generatorName).path
    } catch let error {
      Diagnostics.error("\(generatorName) tool wasn't found")
      throw error
    }

    return [
      .buildCommand(
        displayName: "Generating \(generatedFile)",
        executable: executablePath,
        arguments: ["-o", generatedPath.string, "-m", target.moduleName, "-t", generatedEntryType],
        outputFiles: [generatedPath]
      )
    ]
  }
}
