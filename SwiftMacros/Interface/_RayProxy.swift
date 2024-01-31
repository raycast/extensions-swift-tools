// Copyright © 2024 Raycast. All rights reserved.

import Foundation

public extension _Ray {
  typealias Proxy = _RayProxy
}

/// - todo: Inline in ``_Ray`` after Swift 5.10
public protocol _RayProxy: AnyObject, NSObjectProtocol {
  static func _execute(_ callback: _Ray.Callback)
}
