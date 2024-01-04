// Copyright © 2024 Raycast. All rights reserved.

/// Macro for a global-scope function which generate ObjC types/functions to be dynamically search and executed.
@attached(peer, names: prefixed(_Proxy))
public macro raycast() = #externalMacro(module: "MacrosImplementation", type: "RaycastMacro")
