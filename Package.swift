// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TaxonomyKit",
    products: [
        .library(
            name: "TaxonomyKit",
            targets: ["TaxonomyKit"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "TaxonomyKit",
            dependencies: []),
        .testTarget(
            name: "TaxonomyKitTests",
            dependencies: ["TaxonomyKit"])
    ]
)
