// Copyright © 2024 Raycast. All rights reserved.

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main struct MacrosVendor: CompilerPlugin {
  var providingMacros: [any Macro.Type] {
    [RaycastMacro.self]
  }
}
