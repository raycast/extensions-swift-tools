// Copyright © 2024 Raycast. All rights reserved.

import PackagePlugin
import Foundation

/// Command generating the `d.ts` interface and TypeScript implementation file for a Swift target intended to be used in Raycast extensions.
///
/// This command is customizable by using the following _long_ options:
/// - `--target name` specifies the target being subjected for code generation. If not provided, this command will be applied to all Swift executable targets within the receiving SPM package.
/// - `--attribute name` specifies the Swift attributes indicating that a Swift global function can be used from a Raycast extension. If not provided, this command will infer all `@raycast` Swift attributes as exportable.
///
/// All Command-Line options support multiple input (i.e. `--target name1 --target name2`).
@main struct TypeScriptCodeInterface: CommandPlugin {
  func performCommand(context: PluginContext, arguments: [String]) async throws {
    var arguments = ArgumentExtractor(arguments)
    /// The tool used to generate the TS definition and implementation.
    let generator = try context.tool(named: "TypeScriptCodeGenerator")
    /// The targets that will get code generation.
    let targets = try swiftTargets(context: context, arguments: &arguments)
    /// The attribute name marking the functions to be exported.
    let attributes = try attributeName(arguments: &arguments, default: "@raycast")

    for target in targets {
      var paths: Set<Path> = []
      for file in target.sourceFiles(withSuffix: "swift") {
        guard case .source = file.type, !paths.contains(file.path),
              try await file.contains(attributes: attributes) else { continue }
        paths.insert(file.path)
      }

      guard !paths.isEmpty else {
        Diagnostics.warning("Target '\(target.name) had no file with exported attributes: \(attributes.joined(separator: " or "))")
        continue
      }

      do {
        // 3. Run the TypeScript interface and implementation code generator for all files containing attributes.
        let generatorArguments = ["-t", target.name, "-a"] + attributes + ["-f"] + paths.map(\.string)
        // 4. A single `String` is produced by the Child process containing the target's TS interface and implementation.
        print(try await Process.run(generator.path.url, arguments: generatorArguments).stdout)
      } catch let error {
        Diagnostics.error("Failed to generate TS interface and implementation for target '\(target.name)'")
        throw error
      }
    }
  }
}

private extension TypeScriptCodeInterface {
  func swiftTargets(context: PluginContext, arguments: inout ArgumentExtractor) throws -> [SwiftSourceModuleTarget] {
    let targetedNames = arguments.extractOption(named: "target")
    guard !targetedNames.isEmpty else {
      let targets = context.package.targets(ofType: SwiftSourceModuleTarget.self).filter { $0.kind == .executable }
      if targets.isEmpty { Diagnostics.warning("No executable Swift targets found") }
      return []
    }

    let namedTargets: [Target]
    do {
      namedTargets = try context.package.targets(named: targetedNames)
    } catch let error {
      Diagnostics.error("One (or some) of the specified targets cannot be found")
      throw error
    }

    var targets: [SwiftSourceModuleTarget] = []
    for target in namedTargets {
      guard let swiftTarget = target as? SwiftSourceModuleTarget else {
        Diagnostics.error("Target '\(target.name)' is not a Swift Source target")
        throw Error.unsupportedTarget
      }

      guard case .executable = swiftTarget.kind else {
        Diagnostics.error("Target '\(target.name)' is not executable")
        throw Error.unsupportedTarget
      }

      targets.append(swiftTarget)
    }

    if targets.isEmpty { Diagnostics.warning("No executable Swift targets found") }
    return targets
  }

  func attributeName(arguments: inout ArgumentExtractor, default: String) throws -> [String] {
    let names = arguments.extractOption(named: "attribute")
      .compactMap { $0.drop { $0.isWhitespace } }
      .filter { !$0.isEmpty }

    guard names.isEmpty else { return names.map { String($0) } }

    let defaultName = `default`.drop { $0.isWhitespace }
    guard defaultName.isEmpty else { return [String(defaultName)] }

    Diagnostics.error("No attribute marking exported function was provided")
    throw Error.missingAttributes
  }
}

private enum Error: Swift.Error {
  case unsupportedTarget
  case missingAttributes
}
