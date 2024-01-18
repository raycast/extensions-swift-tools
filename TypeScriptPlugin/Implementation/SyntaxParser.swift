// Copyright © 2024 Raycast. All rights reserved.

import Foundation
import SwiftParser
import SwiftSyntax

extension Sequence where Element == URL {
  func functions(attributes: [String]) async throws -> [ExportableFunction] {
    precondition(!attributes.isEmpty)
    var result: [ExportableFunction] = []

    for fileURL in self {
      let syntax = Parser.parse(source: try String(contentsOf: fileURL))
      let visitor = GlobalAttributedFunctionVisitor(attributes: attributes)
      visitor.walk(syntax)
      result.append(contentsOf: visitor.markedFunctions)
    }

    return result
  }
}

// MARK: -

private final class GlobalAttributedFunctionVisitor: SyntaxVisitor {
  let attributes: [String]
  private(set) var markedFunctions: [ExportableFunction]

  init(attributes: [String]) {
    self.attributes = attributes
    self.markedFunctions = []
    super.init(viewMode: .all)
  }

  override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    for attribute in node.attributes {
      guard let attribute = attribute.as(AttributeSyntax.self),
            attribute.atSign.text == "@",
            let id = attribute.attributeName.as(IdentifierTypeSyntax.self),
            attributes.contains(id.name.text) else { continue }

      let signature = node.signature
      let specifiers = signature.effectSpecifiers
      var match = ExportableFunction(
        attribute: id.name.text,
        name: node.name.text,
        isAsync: specifiers.flatMap(\.asyncSpecifier) != nil,
        isThrowing: specifiers.flatMap(\.throwsSpecifier) != nil
      )

      for param in signature.parameterClause.parameters {
        let paramName: String = switch param.firstName.tokenKind {
        case .identifier(let name): name
        case .wildcard: param.secondName?.text ?? ""
        default: ""
        }
        match.parameters.append((paramName, param.type))
      }

      match.returnType = signature.returnClause?.type
      self.markedFunctions.append(match)
    }
    return .skipChildren
  }

  override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    .skipChildren
  }

  override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    .skipChildren
  }

  override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    .skipChildren
  }

  override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
    .skipChildren
  }
}
