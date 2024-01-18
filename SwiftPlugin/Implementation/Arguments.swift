// Copyright © 2024 Raycast. All rights reserved.

import Foundation

extension CommandLine {
  /// Returns the Swift package target name and the file URLs containing the macro.
  static func structuredArguments(flags outputFlag: String, _ moduleFlag: String, _ typeFlag: String) throws -> (output: URL, module: String, type: String) {
    let arguments = try Self.arguments
    let fileURL = try Self.outputURL(flag: outputFlag, arguments: arguments)
    let moduleName = try Self.moduleName(flag: moduleFlag, arguments: arguments)
    let typeName = try Self.typeName(flag: typeFlag, arguments: consume arguments)
    return (consume fileURL, consume moduleName, consume typeName)
  }
}

private extension CommandLine {
  /// Returns all the constant arguments passed to this command-line tool.
  static var arguments: [String] {
    get throws {
      let args = (count: Int(CommandLine.argc), ptrs: CommandLine.unsafeArgv)
      guard args.count > .zero else { throw EmptyArgumentsError() }

      return (1..<args.count).compactMap {
        guard let arg = args.ptrs[$0] else { return .none }
        return String(cString: arg)
      }
    }
  }

  final class EmptyArgumentsError: LocalizedError {
    let (file, function, line, column): (String, String, Int, Int)

    init(file: String = #fileID, function: String = #function, line: Int = #line, column: Int = #column) {
      (self.file, self.function, self.line, self.column) = (file, function, line, column)
    }

    var errorDescription: String? { "No Command-Line arguments" }
    var failureReason: String? { "\(SwiftCodeGenerator.self) unexpectedly received no arguments" }
  }
}

private extension CommandLine {
  /// Extract the main file output URL from the arguments.
  static func outputURL(flag: String, arguments: borrowing [String]) throws -> URL {
    guard let flagIndex = arguments.firstIndex(of: flag) else { throw MissingOutputFileError(flag: flag) }

    let pathIndex = flagIndex + 1
    guard pathIndex < arguments.endIndex else { throw MissingOutputFileError(flag: flag) }

    let path = arguments[pathIndex].drop { $0.isWhitespace }
    guard !path.isEmpty else { throw MissingOutputFileError(flag: flag) }

    if #available(macOS 13, *) {
      return URL(filePath: String(consume path), directoryHint: .notDirectory)
    } else {
      return URL(fileURLWithPath: String(consume path), isDirectory: false)
    }
  }

  final class MissingOutputFileError: LocalizedError {
    let flag: String
    let (file, function, line, column): (String, String, Int, Int)

    init(flag: String, file: String = #fileID, function: String = #function, line: Int = #line, column: Int = #column) {
      self.flag = flag
      (self.file, self.function, self.line, self.column) = (file, function, line, column)
    }

    var errorDescription: String? { "No output file URL provided" }
    var failureReason: String? { "\(SwiftCodeGenerator.self) requires the definition of the main Swift file URL" }
    var recoverySuggestion: String? { "Pass the \(flag) flag to the \(SwiftCodeGenerator.self) with the URL/Path of the main Swift file" }
    var helpAnchor: String? { "The output file URL defines the location where the @main Swift file is located (usually in the DerivedData build folder" }
  }
}

private extension CommandLine {
  /// Extract the target module name from the arguments.
  static func moduleName(flag: String, arguments: borrowing [String]) throws -> String {
    guard let flagIndex = arguments.firstIndex(of: flag) else { throw MissingModuleError(flag: flag) }

    let moduleIndex = flagIndex + 1
    guard moduleIndex < arguments.endIndex else { throw MissingModuleError(flag: flag) }

    let moduleName = arguments[moduleIndex].drop { $0.isWhitespace }
    guard !moduleName.isEmpty else { throw MissingModuleError(flag: flag) }

    return String(consume moduleName)
  }

  final class MissingModuleError: LocalizedError {
    let flag: String
    let (file, function, line, column): (String, String, Int, Int)

    init(flag: String, file: String = #fileID, function: String = #function, line: Int = #line, column: Int = #column) {
      self.flag = flag
      (self.file, self.function, self.line, self.column) = (file, function, line, column)
    }

    var errorDescription: String? { "No module name provided" }
    var failureReason: String? { "\(SwiftCodeGenerator.self) requires the definition of the module name where the @main Swift file will be generated" }
    var recoverySuggestion: String? { "Pass the \(flag) flag to the \(SwiftCodeGenerator.self) with the name of the module where the main Swift file will be hosted" }
    var helpAnchor: String? { "The module name is required for ObjC runtime search" }
  }
}

private extension CommandLine {
  /// Extract the `@main` type name from the arguments.
  static func typeName(flag: String, arguments: borrowing [String]) throws -> String {
    guard let flagIndex = arguments.firstIndex(of: flag) else { throw MissingTypeName(flag: flag) }

    let nameIndex = flagIndex + 1
    guard nameIndex < arguments.endIndex else { throw MissingTypeName(flag: flag) }

    let typeName = arguments[nameIndex].drop { $0.isWhitespace }
    guard !typeName.isEmpty else { throw MissingTypeName(flag: flag) }

    return String(consume typeName)
  }

  final class MissingTypeName: LocalizedError {
    let flag: String
    let (file, function, line, column): (String, String, Int, Int)

    init(flag: String, file: String = #fileID, function: String = #function, line: Int = #line, column: Int = #column) {
      self.flag = flag
      (self.file, self.function, self.line, self.column) = (file, function, line, column)
    }

    var errorDescription: String? { "No type name provided" }
    var failureReason: String? { "\(SwiftCodeGenerator.self) requires the definition of the @main struct type" }
    var recoverySuggestion: String? { "Pass the \(flag) flag to the \(SwiftCodeGenerator.self) followed by the name of the @main struct type"}
  }
}
