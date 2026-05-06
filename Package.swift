// swift-tools-version: 6.0
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import PackageDescription

let package = Package(
    name: "swift-prometheus",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "Prometheus", targets: ["Prometheus"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin.git", from: "1.4.0")
    ],
    targets: [
        .target(name: "Prometheus"),
        .testTarget(
            name: "PrometheusTests",
            dependencies: ["Prometheus"],
            resources: [.copy("../Vectors")]
        )
    ]
)
