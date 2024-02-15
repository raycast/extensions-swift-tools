// Copyright © 2024 Raycast. All rights reserved.

import XCTest
import MacrosImplementation
import SwiftSyntaxMacrosTestSupport

final class AsyncTests: XCTestCase {
  func testNoop() {
    assertMacroExpansion("""
      @raycast func noop() async {
      }
      """,
      expandedSource: """
      func noop() async {
      }

      @objc final class _Proxynoop: NSObject, _Ray.Proxy {
          static func _execute(_ callback: _Ray.Callback) {
              Task {
                  await noop()
                  callback.forward(value: .none)
              }
          }
      }
      """,
      macros: ["raycast": RaycastMacro.self]
    )
  }

  func testThrowingNoop() {
    assertMacroExpansion("""
      @raycast func noop() async throws {
      }
      """,
      expandedSource: """
      func noop() async throws {
      }

      @objc final class _Proxynoop: NSObject, _Ray.Proxy {
          static func _execute(_ callback: _Ray.Callback) {
              Task {
                  do {
                      try await noop()
                      callback.forward(value: .none)
                  } catch {
                      return callback.forward(error: error)
                  }
              }
          }
      }
      """,
      macros: ["raycast": RaycastMacro.self]
    )
  }

  func testNoArgumentsSimpleReturn() throws {
    assertMacroExpansion("""
      @raycast func greet() async -> String {
          "👋"
      }
      """,
      expandedSource: """
      func greet() async -> String {
          "👋"
      }

      @objc final class _Proxygreet: NSObject, _Ray.Proxy {
          static func _execute(_ callback: _Ray.Callback) {
              Task {
                  let _computedValue = await greet()
                  callback.forward(value: _computedValue)
              }
          }
      }
      """,
      macros: ["raycast": RaycastMacro.self]
    )
  }

  func testSimpleArgumentNoReturn() {
    assertMacroExpansion("""
      @raycast func greet(name: String) async {
          print(name)
      }
      """,
      expandedSource: """
      func greet(name: String) async {
          print(name)
      }

      @objc final class _Proxygreet: NSObject, _Ray.Proxy {
          static func _execute(_ callback: _Ray.Callback) {
              let cmdlineArgs = _Ray.Arguments(dropping: 2)
              guard cmdlineArgs.count >= 1 else {
                  return callback.forward(error: _Ray.MacroError.invalidArguments)
              }
              let name: String
              do {
                  let decoder = JSONDecoder()
                  name = try decoder.decode(String.self, from: cmdlineArgs[0])
              } catch {
                  return callback.forward(error: error)
              }
              Task {
                  await greet(name: name)
                  callback.forward(value: .none)
              }
          }
      }
      """,
      macros: ["raycast": RaycastMacro.self]
    )
  }

  func testMultipleArgumentsNoReturn() {
    assertMacroExpansion("""
      @raycast func greet(name: String, age: Int, _ nickname: String) async {
          print(name, age, nickname)
      }
      """,
      expandedSource: """
      func greet(name: String, age: Int, _ nickname: String) async {
          print(name, age, nickname)
      }

      @objc final class _Proxygreet: NSObject, _Ray.Proxy {
          static func _execute(_ callback: _Ray.Callback) {
              let cmdlineArgs = _Ray.Arguments(dropping: 2)
              guard cmdlineArgs.count >= 3 else {
                  return callback.forward(error: _Ray.MacroError.invalidArguments)
              }
              let name: String
              let age: Int
              let nickname: String
              do {
                  let decoder = JSONDecoder()
                  name = try decoder.decode(String.self, from: cmdlineArgs[0])
                  age = try decoder.decode(Int.self, from: cmdlineArgs[1])
                  nickname = try decoder.decode(String.self, from: cmdlineArgs[2])
              } catch {
                  return callback.forward(error: error)
              }
              Task {
                  await greet(name: name, age: age, nickname)
                  callback.forward(value: .none)
              }
          }
      }
      """,
      macros: ["raycast": RaycastMacro.self]
    )
  }

  func testMultipleArgumentsSimpleThrowingReturn() {
    assertMacroExpansion("""
      @raycast func greet(name: String, age: Int, _ nickname: String) async throws -> String {
          name + String(age) + nickname
      }
      """,
      expandedSource: """
      func greet(name: String, age: Int, _ nickname: String) async throws -> String {
          name + String(age) + nickname
      }

      @objc final class _Proxygreet: NSObject, _Ray.Proxy {
          static func _execute(_ callback: _Ray.Callback) {
              let cmdlineArgs = _Ray.Arguments(dropping: 2)
              guard cmdlineArgs.count >= 3 else {
                  return callback.forward(error: _Ray.MacroError.invalidArguments)
              }
              let name: String
              let age: Int
              let nickname: String
              do {
                  let decoder = JSONDecoder()
                  name = try decoder.decode(String.self, from: cmdlineArgs[0])
                  age = try decoder.decode(Int.self, from: cmdlineArgs[1])
                  nickname = try decoder.decode(String.self, from: cmdlineArgs[2])
              } catch {
                  return callback.forward(error: error)
              }
              Task {
                  do {
                      let _computedValue = try await greet(name: name, age: age, nickname)
                      callback.forward(value: _computedValue)
                  } catch {
                      return callback.forward(error: error)
                  }
              }
          }
      }
      """,
      macros: ["raycast": RaycastMacro.self]
    )
  }
}
