// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AxeptioSDK",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "AxeptioSDK",
            targets: ["AxeptioSDK"]
        ),
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "AxeptioSDK",
            path: "AxeptioSDK.xcframework"
        ),
    ]
)
