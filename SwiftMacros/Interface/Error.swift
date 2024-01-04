// Copyright © 2024 Raycast. All rights reserved.

/// Hidden domain for necessary expanded macro functionality.
public enum _Ray {}

public extension _Ray {
  /// Errors generated within a macro expansion.
  enum MacroError: Swift.Error {
    case invalidArguments
  }
}
