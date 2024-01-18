// Copyright © 2024 Raycast. All rights reserved.

import Foundation

public extension _Ray {
  /// Thread-safe ObjC wrapper over a Swift function result.
  @objc final class Callback: NSObject, @unchecked Sendable {
    private let _lock = NSLock()
    private var _result: R?
    private var _continuation: C?

    public override init() {}

    public var encodedString: String {
      get async throws {
        try await withCheckedThrowingContinuation { continuation in
          _lock.lock()
          if let _result {
            self._result = .none
            _lock.unlock()
            continuation.resume(with: _result)
          } else if case .some = _continuation {
            fatalError("\(_Ray.Callback.self) is not re-entrant")
          } else {
            _continuation = continuation
            _lock.unlock()
          }
        }
      }
    }

    public func forward(error: any Swift.Error) {
      forward(result: .failure(error))
    }

    public func forward(value: (any Encodable)? = .none) {
      guard let value else {
        return forward(result: .success(""))
      }

      do {
        let data = try JSONEncoder().encode(value)
        let str = String(decoding: data, as: UTF8.self)
        forward(result: .success(str))
      } catch {
        forward(error: error)
      }
    }
  }
}

private extension _Ray.Callback {
  typealias R = Result<String, any Swift.Error>
  typealias C = CheckedContinuation<String, any Swift.Error>

  func forward(result: R) {
    _lock.lock()
    if let _continuation {
      self._continuation = .none
      _lock.unlock()
      _continuation.resume(with: result)
    } else {
      _result = result
      _lock.unlock()
    }
  }
}
