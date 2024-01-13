// Copyright © 2024 Raycast. All rights reserved.

import Foundation

struct ExportableFunction {
  let attribute: String
  let name: String
  var parameters: [(name: String, type: String)] = []
  let isAsync: Bool
  let isThrowing: Bool
  var returnType: String?

  var declaration: String {
    var result = "function \(name)("
    result.append(parameters.map { "\($0.name): \(Self.typeScriptType(for: $0.type))" }.joined(separator: ", "))
    result.append("): Promise<")
    result.append(returnType.map { Self.typeScriptType(for: $0) } ?? "void")
    result.append(">;")
    return result
  }

  private static func typeScriptType(for swiftType: String) -> String {
    switch swiftType {
    case "Int8", "Int16", "Int32", "Int64", "Int",
         "UInt8", "UInt16", "UInt32", "UInt64", "UInt",
         "Float16", "Float32", "Double",
         "BinaryInteger", "BinaryFloatingPoint": return "number"
    case "String", "SubString", "StringProtocol": return "string"
    default: return "any"
    }
  }
}
