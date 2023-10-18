import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

private func getFunctionName(from node: some FreestandingMacroExpansionSyntax) throws -> String {
  guard
    /// 1. Grab the first (and only) Macro argument.
    let argument = node.argumentList.first?.expression,
    /// 2. Ensure the argument contains of a single identifier.
    let functionName = argument.as(DeclReferenceExprSyntax.self)?.baseName.text
  else {
    throw RaycastCommandDeclError.onlyApplicableToFunctionWithASingleFunctionArgument
  }

  return functionName
}

public struct RaycastExportFunctionMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) throws -> ExprSyntax {
    let functionName = try getFunctionName(from: node)
    return """
    RaycastExtension.exportFunction(name: "\(raw: functionName)", handler: \(raw: functionName))
    """
  }
}

public struct RaycastHandleFunctionCallMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) throws -> ExprSyntax {
    return """
    RaycastExtension.handleFunctionCall()
    """
  }
}

public enum RaycastCommandDeclError: CustomStringConvertible, Error {
  case onlyApplicableToFunctionWithASingleFunctionArgument

  public var description: String {
    switch self {
    case .onlyApplicableToFunctionWithASingleFunctionArgument:
      "#exportFunction can only be applied to a function with the following signature: func someMethodName(input: InputType) async throws -> OutputType"
   }
  }
}

@main
struct RaycastExtensionMacroPlugin: CompilerPlugin {
  let providingMacros: [SwiftSyntaxMacros.Macro.Type] = [
    RaycastExportFunctionMacro.self,
    RaycastHandleFunctionCallMacro.self,
  ]
}
