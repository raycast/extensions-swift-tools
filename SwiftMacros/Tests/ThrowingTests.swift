// Copyright © 2024 Raycast. All rights reserved.

import XCTest
import MacrosImplementation
import SwiftSyntaxMacrosTestSupport

final class ThrowingTests: XCTestCase {
  func testNoop() {
    assertMacroExpansion("""
      @raycast func noop() throws {
      }
      """,
      expandedSource: """
      func noop() throws {
      }

      @objc final class _Proxynoop: NSObject, _Ray.Proxy {
          static func _execute(_ callback: _Ray.Callback) {
              do {
                  try noop()
                  callback.forward(value: .none)
              } catch {
                  return callback.forward(error: error)
              }
          }
      }
      """,
      macros: ["raycast": RaycastMacro.self]
    )
  }

  func testNoArgumentsSimpleReturn() throws {
    assertMacroExpansion("""
      @raycast func greet() throws -> String {
          "👋"
      }
      """,
      expandedSource: """
      func greet() throws -> String {
          "👋"
      }

      @objc final class _Proxygreet: NSObject, _Ray.Proxy {
          static func _execute(_ callback: _Ray.Callback) {
              do {
                  let _computedValue = try greet()
                  callback.forward(value: _computedValue)
              } catch {
                  return callback.forward(error: error)
              }
          }
      }
      """,
      macros: ["raycast": RaycastMacro.self]
    )
  }

  func testSimpleArgumentNoReturn() {
    assertMacroExpansion("""
      @raycast func greet(name: String) throws {
          print(name)
      }
      """,
      expandedSource: """
      func greet(name: String) throws {
          print(name)
      }

      @objc final class _Proxygreet: NSObject, _Ray.Proxy {
          static func _execute(_ callback: _Ray.Callback) {
              let cmdlineArgs = _Ray.Arguments(dropping: 2)
              guard cmdlineArgs.count >= 1 else {
                  return callback.forward(error: _Ray.MacroError.invalidArguments)
              }
              let name: String
              let _argsDecoder = JSONDecoder()
              do {
                  name = try _argsDecoder.decode(String.self, from: cmdlineArgs[0])
              } catch {
                  let _argError = _Ray.DecodingArgumentError(name: "name", position: 0, type: String.self, data: cmdlineArgs[0], underlying: error)
                  return callback.forward(error: _argError)
              }
              do {
                  try greet(name: name)
                  callback.forward(value: .none)
              } catch {
                  return callback.forward(error: error)
              }
          }
      }
      """,
      macros: ["raycast": RaycastMacro.self]
    )
  }

  func testMultipleArgumentsNoReturn() {
    assertMacroExpansion("""
      @raycast func greet(name: String, age: Int, _ nickname: String) throws {
          print(name, age, nickname)
      }
      """,
      expandedSource: """
      func greet(name: String, age: Int, _ nickname: String) throws {
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
              let _argsDecoder = JSONDecoder()
              do {
                  name = try _argsDecoder.decode(String.self, from: cmdlineArgs[0])
              } catch {
                  let _argError = _Ray.DecodingArgumentError(name: "name", position: 0, type: String.self, data: cmdlineArgs[0], underlying: error)
                  return callback.forward(error: _argError)
              }
              do {
                  age = try _argsDecoder.decode(Int.self, from: cmdlineArgs[1])
              } catch {
                  let _argError = _Ray.DecodingArgumentError(name: "age", position: 1, type: Int.self, data: cmdlineArgs[1], underlying: error)
                  return callback.forward(error: _argError)
              }
              do {
                  nickname = try _argsDecoder.decode(String.self, from: cmdlineArgs[2])
              } catch {
                  let _argError = _Ray.DecodingArgumentError(name: "nickname", position: 2, type: String.self, data: cmdlineArgs[2], underlying: error)
                  return callback.forward(error: _argError)
              }
              do {
                  try greet(name: name, age: age, nickname)
                  callback.forward(value: .none)
              } catch {
                  return callback.forward(error: error)
              }
          }
      }
      """,
      macros: ["raycast": RaycastMacro.self]
    )
  }

  func testMultipleArgumentsSimpleReturn() {
    assertMacroExpansion("""
      @raycast func greet(name: String, age: Int, _ nickname: String) throws -> String {
          name + String(age) + nickname
      }
      """,
      expandedSource: """
      func greet(name: String, age: Int, _ nickname: String) throws -> String {
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
              let _argsDecoder = JSONDecoder()
              do {
                  name = try _argsDecoder.decode(String.self, from: cmdlineArgs[0])
              } catch {
                  let _argError = _Ray.DecodingArgumentError(name: "name", position: 0, type: String.self, data: cmdlineArgs[0], underlying: error)
                  return callback.forward(error: _argError)
              }
              do {
                  age = try _argsDecoder.decode(Int.self, from: cmdlineArgs[1])
              } catch {
                  let _argError = _Ray.DecodingArgumentError(name: "age", position: 1, type: Int.self, data: cmdlineArgs[1], underlying: error)
                  return callback.forward(error: _argError)
              }
              do {
                  nickname = try _argsDecoder.decode(String.self, from: cmdlineArgs[2])
              } catch {
                  let _argError = _Ray.DecodingArgumentError(name: "nickname", position: 2, type: String.self, data: cmdlineArgs[2], underlying: error)
                  return callback.forward(error: _argError)
              }
              do {
                  let _computedValue = try greet(name: name, age: age, nickname)
                  callback.forward(value: _computedValue)
              } catch {
                  return callback.forward(error: error)
              }
          }
      }
      """,
      macros: ["raycast": RaycastMacro.self]
    )
  }
}
