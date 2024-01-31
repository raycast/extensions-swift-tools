// Copyright © 2024 Raycast. All rights reserved.

import Foundation
import SwiftSyntax

struct ExportableFunction: @unchecked Sendable {
  let attribute: String
  let name: String
  var parameters: [(name: String, type: TypeSyntax)] = []
  let isAsync: Bool
  let isThrowing: Bool
  var returnType: TypeSyntax?
}

extension ExportableFunction {
  var typescriptInterface: String {
    var result = "function \(name)("
    result.append(parameters.map { "\($0.name)\(Self.isOptional(type: $0.type) ? "?" : ""): \(Self.typeScriptType(for: $0.type))" }.joined(separator: ", "))
    result.append("): Promise<")
    result.append(returnType.map { Self.typeScriptType(for: $0) } ?? "void")
    result.append(">")
    return result
  }

  func typescriptImplementation(runner: String) -> String {
    var result = typescriptInterface
    result.append(" {\n")
    result.append(#"  return await \#(runner)("\#(name)""#)
    if !parameters.isEmpty {
      result.append(", ")
      result.append(parameters.map(\.name).joined(separator: ", "))
    }
    result.append(")\n}")
    return result
  }

  var javascriptInterface: String {
    var result = "async function \(name)("
    result.append(parameters.map(\.name).joined(separator: ", "))
    result.append(")")
    return result
  }

  func javascriptImplementation(runner: String) -> String {
    var result = javascriptInterface
    result.append(" {\n")
    result.append(#"  return await \#(runner)("\#(name)""#)
    if !parameters.isEmpty {
      result.append(", ")
      result.append(parameters.map(\.name).joined(separator: ", "))
    }
    result.append(")\n}")
    return result
  }
}

private extension ExportableFunction {
  static func isOptional(type swiftType: TypeSyntax) -> Bool {
    guard case .some = swiftType.as(OptionalTypeSyntax.self) else { return false }
    return true
  }

  static func typeScriptType(for swiftType: TypeSyntax) -> String {
    if let type = swiftType.as(OptionalTypeSyntax.self) {
      return "\(typeScriptType(for: type.wrappedType)) | null"
    } else if let type = swiftType.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
      return typeScriptType(for: type.wrappedType)
    } else if let type = swiftType.as(SomeOrAnyTypeSyntax.self) {
      return typeScriptType(for: type.constraint)
    } else if case .some = swiftType.as(MetatypeTypeSyntax.self) {
      return "any"
    } else if let type = swiftType.as(ArrayTypeSyntax.self) {
      return "\(typeScriptType(for: type.element))[]"
    } else if let type = swiftType.as(DictionaryTypeSyntax.self) {
      return "{ [key: \(typeScriptType(for: type.key))]: \(typeScriptType(for: type.value)) }"
    }

    guard let type = swiftType.as(IdentifierTypeSyntax.self),
          case .identifier(let name) = type.name.tokenKind else { return "any" }

    if let args = type.genericArgumentClause?.arguments {
      switch name {
      case "Set" where args.count == 1: return "Set<\(typeScriptType(for: args.first!.argument))>"
      case "Array" where args.count == 1: return "\(typeScriptType(for: args.first!.argument))[]"
      case "Dictionary" where args.count == 2:
        let s = args.startIndex, e = args.index(after: s)
        return "{ [key: \(typeScriptType(for: args[s].argument))]: \(typeScriptType(for: args[e].argument)) }"
      default: return "any"
      }
    } else {
      switch name {
      case "Bool": return "boolean"
      case "Int8", "Int16", "Int32", "Int64", "Int",
           "UInt8", "UInt16", "UInt32", "UInt64", "UInt",
           "Float16", "Float32", "Double",
           "BinaryInteger", "BinaryFloatingPoint": return "number"
      case "String", "SubString", "StringProtocol": return "string"
      default: return "any"
      }
    }
  }
}
