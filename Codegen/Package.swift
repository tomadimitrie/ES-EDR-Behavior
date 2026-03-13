// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Codegen",
    platforms: [.macOS(.v15)],
    products: [
        .library(
            name: "Codegen",
            targets: ["Codegen"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.0-latest"),
    ],
    targets: [
        .macro(
            name: "CodegenMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(name: "Codegen", dependencies: ["CodegenMacros"]),
    ]
)
