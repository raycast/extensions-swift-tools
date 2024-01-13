// Copyright © 2024 Raycast. All rights reserved.

import Foundation

extension CommandLine {
  /// Returns the Swift package target name and the file URLs containing the macro.
  static func structuredArguments(flags targetFlag: String, _ attributesFlag: String, _ filesFlag: String) throws -> (target: String, attributes: [String], files: [URL]) {
    let arguments = try Self.arguments
    let targetName = try Self.targetName(flag: targetFlag, arguments: arguments)
    let attributes = try Self.attributes(flag: attributesFlag, arguments: arguments)
    let fileURLs = try Self.fileURLs(flag: filesFlag, arguments: consume arguments)
    return (consume targetName, consume attributes, consume fileURLs)
  }
}

// MARK: -

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
    var failureReason: String? { "\(TypeScriptCodeGenerator.self) unexpectedly received no arguments" }
  }
}

private extension CommandLine {
  static func targetName(flag: String, arguments: borrowing [String]) throws -> String {
    guard let flagIndex = arguments.firstIndex(of: flag) else { throw MissingTargetError(flag: flag) }

    let nameIndex = flagIndex + 1
    guard nameIndex < arguments.endIndex else { throw MissingTargetError(flag: flag) }

    let name = arguments[nameIndex].drop { $0.isWhitespace }
    guard !name.isEmpty else { throw MissingTargetError(flag: flag) }

    return String(consume name)
  }

  final class MissingTargetError: LocalizedError {
    let flag: String
    let (file, function, line, column): (String, String, Int, Int)

    init(flag: String, file: String = #fileID, function: String = #function, line: Int = #line, column: Int = #column) {
      self.flag = flag
      (self.file, self.function, self.line, self.column) = (file, function, line, column)
    }

    var errorDescription: String? { "No target name provided" }
    var failureReason: String? { "\(TypeScriptCodeGenerator.self) requires the definition of the Swift executable target name" }
    var recoverySuggestion: String? { "Pass the \(flag) flag to the \(TypeScriptCodeGenerator.self) followed by the name of the target" }
  }
}

private extension CommandLine {
  static func attributes(flag: String, arguments: borrowing [String]) throws -> [String] {
    guard let flagIndex = arguments.firstIndex(of: flag) else { throw MissingAttributesError(flag: flag) }

    let startIndex = flagIndex + 1
    let attrs = try arguments[startIndex..<arguments.endIndex]
      .prefix { !$0.hasPrefix("-") }
      .filter { $0.contains { !$0.isWhitespace } }
      .map {
        guard $0.hasPrefix("@") else { throw UnsupportedAttributesError() }
        return String($0.dropFirst())
      }.reduce(into: Set<String>()) { $0.insert($1) }

    guard !attrs.isEmpty else { throw MissingAttributesError(flag: flag) }
    return Array(attrs)
  }

  final class MissingAttributesError: LocalizedError {
    let flag: String
    let (file, function, line, column): (String, String, Int, Int)

    init(flag: String, file: String = #fileID, function: String = #function, line: Int = #line, column: Int = #column) {
      self.flag = flag
      (self.file, self.function, self.line, self.column) = (file, function, line, column)
    }

    var errorDescription: String? { "No attributes provided" }
    var failureReason: String? { "\(TypeScriptCodeGenerator.self) requires the definition of the Swift macros/attributes marking functions as exportable" }
    var recoverySuggestion: String? { "Pass the \(flag) flag to the \(TypeScriptCodeGenerator.self) followed by one or more attributes" }
  }

  final class UnsupportedAttributesError: LocalizedError {
    let (file, function, line, column): (String, String, Int, Int)

    init(file: String = #fileID, function: String = #function, line: Int = #line, column: Int = #column) {
      (self.file, self.function, self.line, self.column) = (file, function, line, column)
    }

    var errorDescription: String? { "Swift attributes currently not supported" }
    var failureReason: String? { "\(TypeScriptCodeGenerator.self) currently only supports @ attributes" }
    var recoverySuggestion: String? { "Make sure all passed attributes are @name" }
  }
}

private extension CommandLine {
  static func fileURLs(flag: String, arguments: borrowing [String]) throws -> [URL] {
    guard let flagIndex = arguments.firstIndex(of: flag) else { throw MissingFilesError(flag: flag) }

    let manager = FileManager.default
    let startIndex = flagIndex + 1
    return arguments[startIndex..<arguments.endIndex]
      .prefix { !$0.hasPrefix("-") }
      .filter { $0.contains { !$0.isWhitespace } && manager.fileExists(atPath: $0) }
      .reduce(into: Set<String>()) { $0.insert($1) }
      .map {
        if #available(macOS 13, *) {
          URL(filePath: $0)
        } else {
          URL(fileURLWithPath: $0)
        }
      }
  }

  final class MissingFilesError: LocalizedError {
    let flag: String
    let (file, function, line, column): (String, String, Int, Int)

    init(flag: String, file: String = #fileID, function: String = #function, line: Int = #line, column: Int = #column) {
      self.flag = flag
      (self.file, self.function, self.line, self.column) = (file, function, line, column)
    }

    var errorDescription: String? { "No files provided" }
    var failureReason: String? { "\(TypeScriptCodeGenerator.self) requires the definition of files to introspect" }
    var recoverySuggestion: String? { "Pass the \(flag) flag to the \(TypeScriptCodeGenerator.self) followed by the one or multiple file paths" }
  }
}
