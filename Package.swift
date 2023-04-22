// swift-tools-version:5.8

import PackageDescription

let package = Package(
  name: "swift-gen",
  platforms: [.iOS(.v13), .macOS(.v10_14), .tvOS(.v13)],
  products: [
    .library(name: "Gen", targets: ["Gen"])
  ],
  targets: [
    .target(name: "Gen", dependencies: []),
    .testTarget(name: "GenTests", dependencies: ["Gen"]),
  ]
)
