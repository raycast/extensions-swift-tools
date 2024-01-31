// Copyright © 2024 Raycast. All rights reserved.

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Attached peer macro for global-scope functions which generates an ObjC type for each associated function.
public struct RaycastMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let functionDecl = declaration.as(FunctionDeclSyntax.self) else {
      throw Error.invalidMacroTarget
    }

    guard !functionDecl.modifiers.contains(where: { $0.name.text.lowercased() == "static" }) else {
      throw Error.unsupportedStaticFunction
    }

    let funcName = functionDecl.name.text
    let signature = functionDecl.signature
    let isAsync = signature.effectSpecifiers?.asyncSpecifier != nil
    let isThrow = signature.effectSpecifiers?.throwsSpecifier != nil
    let parameters = signature.parameterClause.parameters
    let returnType = signature.returnClause.map { "\($0.type)" }
    let isReturning = !(returnType.flatMap { $0 == "Void" || $0 == "()" } ?? true)

    let typeDecl = "@objc final class _Proxy\(funcName): NSObject, _Ray.Proxy"
    let funcDecl = "static func _execute(_ callback: _Ray.Callback)"

    guard !parameters.isEmpty else {
      if !isThrow {
        return [
          """
          \(raw: typeDecl) {
            \(raw: funcDecl) {
              \(raw: isReturning ? "let value = " : "")\(raw: isAsync ? "await " : "")\(raw: funcName)()
              callback.forward(value: \(raw: isReturning ? "value" : ".none"))
            }
          }
          """
        ]
      } else {
        return [
          """
          \(raw: typeDecl) {
            \(raw: funcDecl) {
              do {
                \(raw: isReturning ? "let value = " : "")try \(raw: isAsync ? "await " : "")\(raw: funcName)()
                callback.forward(value: \(raw: isReturning ? "value" : ".none"))
              } catch {
                callback.forward(error: error)
              }
            }
          }
          """
        ]
      }
    }

    let localVars: [(name: String, type: String)] = parameters.map { (($0.secondName ?? $0.firstName).text, "\($0.type)") }
    let localDecl = localVars.map { "\($0.name): \($0.type)" }.joined(separator: ", ")
    let decoding = localVars.enumerated().map { "\($1.name) = try decoder.decode(\($1.type).self, from: cmdlineArgs[\($0)])" }.joined(separator: "\n\t\t")
    let arguments = zip(parameters, localVars).map { "\($0.firstName): \($1.name)" }.joined(separator: ", ")

    let firstPart: String = """
    let cmdlineArgs = _Ray.Arguments(dropping: 2)
    guard cmdlineArgs.count >= \(parameters.count) else { return callback.forward(error: _Ray.MacroError.invalidArguments) }

    let \(localDecl)
    do {
      let decoder = JSONDecoder()
      \(decoding)
    } catch {
      return callback.forward(error: error)
    }
    """

    let secondPart: String = if isThrow {
      """
      do {
        \(isReturning ? "let value = " : "")try \(isAsync ? "await " : "")\(funcName)(\(arguments))
        callback.forward(value: \(isReturning ? "value" : ".none"))
      } catch {
        callback.forward(error: error)
      }
      """
    } else {
      """
        \(isReturning ? "let value = " : "")\(isAsync ? "await " : "")\(funcName)(\(arguments))
        callback.forward(value: \(isReturning ? "value" : ".none"))
      """
    }

    return [
      """
      \(raw: typeDecl) {
        \(raw: funcDecl) {
          \(raw: firstPart)
            \(raw: isAsync ? "Task {\n\t" : "")\
            \(raw: secondPart)
            \(raw: isAsync ? "}" : "")
        }
      }
      """
    ]
  }
}

public extension RaycastMacro {
  enum Error: Swift.Error {
    /// This macro can only be applied to a function.
    case invalidMacroTarget
    /// This macro cannot be applied to static functions.
    case unsupportedStaticFunction
  }
}
