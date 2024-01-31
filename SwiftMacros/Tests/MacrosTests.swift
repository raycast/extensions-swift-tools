// Copyright © 2024 Raycast. All rights reserved.

import XCTest
import MacrosImplementation
import SwiftSyntaxMacrosTestSupport

final class MacrosTests: XCTestCase {
  /// - todo: `RaycastMacro` currently doesn't write correct indentation.
  func testExample() throws {
    assertMacroExpansion("""
      @raycast func greet() -> String {
        "🎄🎄🎄🎄🎄🎄🎄🎄"
      }
      """,
      expandedSource: """
      func greet() -> String {
        "🎄🎄🎄🎄🎄🎄🎄🎄"
      }

      @objc final class _Proxygreet: NSObject, _Ray.Proxy {
        static func _execute(_ callback: _Ray.Callback) {
          let value = greet()
          callback.forward(value: value)
        }
      }
      """,
      macros: ["raycast": RaycastMacro.self]
    )
  }
}
