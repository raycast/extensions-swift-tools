// swift-tools-version: 5.9
import PackageDescription
import CompilerPluginSupport

let package = Package(
  name: "raycast-extension-macro",
  platforms: [
    .macOS(.v12)
  ],
  products: [
    .library(
      name: "RaycastSwiftMacros",
      targets: ["RaycastSwiftMacros"]
    ),
    .plugin(
      name: "RaycastSwiftPlugin",
      targets: ["RaycastSwiftPlugin"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-syntax.git", from: "509.1.0"),
  ],
  targets: [

    // Swift macros

    .target(
      name: "RaycastSwiftMacros",
      dependencies: [
        .target(name: "MacrosImplementation")
      ],
      path: "SwiftMacros/Interface",
      swiftSettings: .swiftSettings
    ),

    .macro(
      name: "MacrosImplementation",
      dependencies: [
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
      ],
      path: "SwiftMacros/Implementation",
      packageAccess: true,
      swiftSettings: .swiftSettings
    ),

//    .testTarget(
//      name: "RaycastSwiftMacrosTests",
//      dependencies: [
//        .target(name: "MacrosImplementation"),
//        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
//        .product(name: "SwiftSyntax", package: "swift-syntax"),
//        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
//        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
//        .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
//      ],
//      path: "SwiftMacros/Tests",
//      packageAccess: true,
//      swiftSettings: .swiftSettings
//    )

    // Swift plugin

    .plugin(
      name: "RaycastSwiftPlugin",
      capability: .buildTool(),
      dependencies: [
        .target(name: "SwiftCodeGenerator")
      ],
      path: "SwiftPlugin/Interface"
    ),

    .executableTarget(
      name: "SwiftCodeGenerator",
      path: "SwiftPlugin/Implementation",
      swiftSettings: .swiftSettings
    )
  ],
  swiftLanguageVersions: [.v5]
)

private extension Array<SwiftSetting> {
  static var swiftSettings: Self {
    [
      .enableUpcomingFeature("ConciseMagicFile"),
      .enableUpcomingFeature("DisableOutwardActorInference"),
      .enableUpcomingFeature("ExistentialAny"),
      .enableUpcomingFeature("ForwardTrailingClosures"),
      .enableUpcomingFeature("StrictConcurrency"),
      .unsafeFlags(["-warn-concurrency", "-enable-actor-data-race-checks"]),
    ]
  }
}
