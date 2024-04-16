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

    let generatedDeclaration = try ClassDeclSyntax(
      "@objc final class _Proxy\(functionDecl.name): NSObject, _Ray.Proxy"
    ) {
      try FunctionDeclSyntax("static func _execute(_ callback: _Ray.Callback)") {
        let signature = functionDecl.signature
        let parameters = signature.parameterClause.parameters
        // If the function declares parameters, the values need to be extracted from argv
        if !parameters.isEmpty {
          try VariableDeclSyntax("let cmdlineArgs = _Ray.Arguments(dropping: 2)")
          GuardStmtSyntax(conditions: [ConditionElementSyntax(condition: .expression("cmdlineArgs.count >= \(raw: parameters.count)"))]) {
            "return callback.forward(error: _Ray.MacroError.invalidArguments)"
          }

          // Declare all the local variables holding the values decoded from the Command-line arguments
          for param in parameters {
            "let \(raw: param.secondName?.text ?? param.firstName.text): \(param.type)"
          }
          try VariableDeclSyntax("let _argsDecoder = JSONDecoder()")

          // do-catch statement JSON decoding the values in argv
          for (i, param) in parameters.enumerated() {
            DoStmtSyntax(body: CodeBlockSyntax {
              "\(raw: param.secondName?.text ?? param.firstName.text) = try _argsDecoder.decode(\(param.type).self, from: cmdlineArgs[\(raw: i)])"
            }, catchClauses: CatchClauseListSyntax {
              CatchClauseSyntax {
                #"let _argError = _Ray.DecodingArgumentError(name: "\#(raw: param.secondName?.text ?? param.firstName.text)", position: \#(raw: i), type: \#(param.type).self, data: cmdlineArgs[\#(raw: i)], underlying: error)"#
                "return callback.forward(error: _argError)"
              }
            })
          }
        }

        let isAsync = signature.effectSpecifiers?.asyncSpecifier != nil
        let isThrow = signature.effectSpecifiers?.throwsSpecifier != nil
        let isReturning = Self.isReturning(clause: signature.returnClause)

        // Expression calling the actual targeted Swift function
        let swiftFunction = FunctionCallExprSyntax(
          calledExpression: DeclReferenceExprSyntax(baseName: .identifier(functionDecl.name.text)),
          leftParen: .leftParenToken(),
          rightParen: .rightParenToken(),
          argumentsBuilder: {
            for param in parameters {
              let isWildCard = param.firstName.tokenKind == .wildcard
              LabeledExprSyntax(
                label: isWildCard ? .none : "\(raw: param.firstName.text)",
                colon: isWildCard ? .none : .colonToken(),
                expression: DeclReferenceExprSyntax(baseName: .identifier((param.secondName ?? param.firstName).text))
              )
            }
          }
        )
        // Expressing including the `try` and `await` keywords (if necessary)
        let swiftExpression: any ExprSyntaxProtocol = switch (isThrow, isAsync) {
        case (true, true): TryExprSyntax(tryKeyword: .keyword(.try, trailingTrivia: " "), expression: AwaitExprSyntax(awaitKeyword: .keyword(.await, trailingTrivia: " "), expression: swiftFunction))
        case (true, false): TryExprSyntax(tryKeyword: .keyword(.try, trailingTrivia: " "), expression: swiftFunction)
        case (false, true): AwaitExprSyntax(awaitKeyword: .keyword(.await, trailingTrivia: " "), expression: swiftFunction)
        case (false, false): swiftFunction
        }

        let callAndAnswer = CodeBlockItemListSyntax {
          "\(raw: isReturning ? "let _computedValue = " : "")\(raw: swiftExpression)"
          "callback.forward(value: \(raw: isReturning ? "_computedValue" : ".none"))"
        }

        let lastBlock = !isThrow ? callAndAnswer : CodeBlockItemListSyntax {
          DoStmtSyntax(body: CodeBlockSyntax {
            callAndAnswer
          }, catchClauses: CatchClauseListSyntax {
            CatchClauseSyntax { "return callback.forward(error: error)" }
          })
        }

        if isAsync {
          FunctionCallExprSyntax(
            callee: DeclReferenceExprSyntax(baseName: .identifier("Task")),
            trailingClosure: ClosureExprSyntax { lastBlock }
          )
        } else {
          lastBlock
        }
      }
    }

    return [DeclSyntax(generatedDeclaration)]
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

// MARK: -

private extension RaycastMacro {
  static func isReturning(clause: ReturnClauseSyntax?) -> Bool {
    guard let returnType = clause?.type else { return false }

    if let type = returnType.as(IdentifierTypeSyntax.self) {
      guard case .identifier("Void") = type.name.tokenKind else { return true }
      return false
    } else if let type = returnType.as(TupleTypeSyntax.self) {
      return !type.elements.isEmpty
    } else {
      return true
    }
  }
}
