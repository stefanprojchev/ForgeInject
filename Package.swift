// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "ForgeInject",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "ForgeInject",
            targets: ["ForgeInject"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "601.0.0"),
    ],
    targets: [
        // The macro plugin target — runs in the compiler at build time.
        .macro(
            name: "ForgeInjectMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        // The library users import — declares the macros and the container.
        .target(
            name: "ForgeInject",
            dependencies: ["ForgeInjectMacros"]
        ),
        .testTarget(
            name: "ForgeInjectTests",
            dependencies: ["ForgeInject"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
