import Foundation

public class RaycastExtension {
  private static var matchers: [String: (_ inputString: String?) async throws -> Any?] = [:]

  @discardableResult
  public static func exportFunction(name: String, handler: @escaping () async throws -> Void) -> Bool {
    matchers[name] = { _ in
      try await handler()
      return nil
    }
    return true
  }

  @discardableResult
  public static func exportFunction(name: String, handler: @escaping () async throws -> Any?) -> Bool {
    matchers[name] = { _ in
      return try await handler()
    }
    return true
  }

  @discardableResult
  public static func exportFunction<T>(name: String, handler: @escaping (_ data: T) async throws -> Void) -> Bool {
    matchers[name] = { inputString in
      let input = self.parseInput(inputString, functionName: name) as T
      try await handler(input)
      return nil
    }
    return true
  }

  @discardableResult
  public static func exportFunction<T>(name: String, handler: @escaping (_ data: T) async throws -> Any?) -> Bool {
    matchers[name] = { inputString in
      let input = self.parseInput(inputString, functionName: name) as T
      return try await handler(input)
    }
    return true
  }

  public static func handleFunctionCall() -> Bool {
    Task(priority: .userInitiated) {
      await main()
    }
    RunLoop.main.run()
    return true
  }

  private static func main() async {
    let argv = Array(CommandLine.arguments[1...])
    if argv.count < 1 {
      errPrint("Missing command")
      exit(1)
    }
    let command = argv[0]
    let inputString = argv.count < 2 ? nil : argv[1]

    guard let matcher = matchers[command] else {
      errPrint("Could not find command \(command)")
      exit(1)
    }

    let result: Any?
    do {
      result = try await matcher(inputString)
    } catch let error {
      errPrint("Error running command \(command): \(error.localizedDescription)")
      exit(1)
    }

    if let result {
      do {
        let jsonData: Data

        if let result = result as? Encodable {
          jsonData = try JSONEncoder().encode(result)
        } else {
          jsonData = try JSONSerialization.data(withJSONObject: result, options: .fragmentsAllowed)
        }

        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
          errPrint("Failed to convert JSON data from \(command) to string")
          exit(1)
        }

        print(jsonString)
        exit(0)
      } catch let error {
        errPrint("Failed to serialize result from \(command) to JSON: \(error.localizedDescription)")
        exit(1)
      }
    } else {
      exit(0)
    }
  }

  private static func parseInput<T>(_ inputString: String?, functionName: String) -> T where T : Decodable {
    if let data = inputString?.data(using: .utf8) {
      do {
        return try JSONDecoder().decode(T.self, from: data)
      } catch let error {
        errPrint("Failed to parse input for the \(functionName) command: \(error)")
        exit(1)
      }
    } else {
      errPrint("Failed to parse input for the \(functionName) command")
      exit(1)
    }
  }

  private static func parseInput<T>(_ inputString: String?, functionName: String) -> T {
    if let data = inputString?.data(using: .utf8) {
      do {
        if let parsedData = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? T {
          return parsedData
        } else {
          errPrint("Failed to parse input for the \(functionName) command: expected \(T.self)")
          exit(1)
        }
      } catch let error {
        errPrint("Failed to parse input for the \(functionName) command: \(error)")
        exit(1)
      }
    } else {
      errPrint("Failed to parse input for the \(functionName) command")
      exit(1)
    }
  }

  private static func errPrint(_ string: String) {
    var errStream = StandardErrorOutputStream()
    print(string, to: &errStream)
  }
}

private struct StandardErrorOutputStream: TextOutputStream {
  let stderr = FileHandle.standardError

  func write(_ string: String) {
    guard let data = string.data(using: .utf8) else {
      stderr.write("unknown error".data(using: .utf8)!)
      return
    }
    stderr.write(data)
  }
}
