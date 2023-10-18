/// A macro that expose a swift function as a function accessible from a Raycast extension. For example,
/// ```
/// #exportFunction(pickColor)
/// func pickColor() -> Color? { ... }
/// ```
/// produces a function that can be called from a Raycast extension.
@freestanding(expression)
public macro exportFunction<Input>(_ fn: (Input) async throws -> Any?) -> Bool = #externalMacro(module: "MacroImplementation", type: "RaycastExportFunctionMacro")

/// A macro that expose a swift function as a function accessible from a Raycast extension. For example,
/// ```
/// #exportFunction(pickColor)
/// func pickColor() -> Color? { ... }
/// ```
/// produces a function that can be called from a Raycast extension.
@freestanding(expression)
public macro exportFunction(_ fn: () async throws -> Any?) -> Bool = #externalMacro(module: "MacroImplementation", type: "RaycastExportFunctionMacro")

/// A macro that expose a swift function as a function accessible from a Raycast extension. For example,
/// ```
/// #exportFunction(pickColor)
/// func pickColor() -> Color? { ... }
/// ```
/// produces a function that can be called from a Raycast extension.
@freestanding(expression)
public macro exportFunction<Input>(_ fn: (Input) async throws -> Void) -> Bool = #externalMacro(module: "MacroImplementation", type: "RaycastExportFunctionMacro")

/// A macro that expose a swift function as a function accessible from a Raycast extension. For example,
/// ```
/// #exportFunction(pickColor)
/// func pickColor() -> Color? { ... }
/// ```
/// produces a function that can be called from a Raycast extension.
@freestanding(expression)
public macro exportFunction(_ fn: () async throws -> Void) -> Bool = #externalMacro(module: "MacroImplementation", type: "RaycastExportFunctionMacro")

/// A macro that expose a swift function as a function accessible from a Raycast extension. For example,
/// ```
/// #exportFunction(pickColor)
/// func pickColor() -> Color? { ... }
/// ```
/// produces a function that can be called from a Raycast extension.
@freestanding(expression)
public macro handleFunctionCall() -> Bool = #externalMacro(module: "MacroImplementation", type: "RaycastHandleFunctionCallMacro")
