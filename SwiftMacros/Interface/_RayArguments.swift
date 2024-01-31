// Copyright © 2024 Raycast. All rights reserved.

import Foundation

public extension _Ray {
  /// Wrapper over the CommandLine arguments (dropping the first argument, which is the CLI program name).
  ///
  /// Arguments are only decoded on-demand (i.e. _lazy_ approach).
  struct Arguments: Collection {
    private let args = CommandLine.unsafeArgv
    private let droppedElements: Int
    public let endIndex: Int

    public init(dropping numElements: Int) {
      self.droppedElements = numElements
      self.endIndex = Int(CommandLine.argc) - numElements
      precondition(self.endIndex >= .zero)
    }

    public var startIndex: Int {
      .zero
    }

    public func index(after i: Int) -> Int {
      i + 1
    }

    public subscript(position: Int) -> Data {
      precondition(position < endIndex)
      guard let ptr = args[position + droppedElements] else { return Data() }
      let bytesCount = strlen(ptr)
      return Data(bytes: ptr, count: bytesCount)
    }

    public func makeIterator() -> Self.Iterator {
      Self.Iterator(self)
    }
  }
}

public extension _Ray.Arguments {
  struct Iterator: IteratorProtocol {
    private var index: Int = 0
    private let storage: _Ray.Arguments

    fileprivate init(_ storage: _Ray.Arguments) {
      self.storage = storage
    }

    public mutating func next() -> Data? {
      guard index < storage.endIndex else { return .none }
      defer { index += 1 }
      return storage[index]
    }

    public typealias Element = Data
  }
}
