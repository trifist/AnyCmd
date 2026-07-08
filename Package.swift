// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AnyCmd",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "AnyCmd", targets: ["AnyCmd"])
    ],
    targets: [
        .executableTarget(
            name: "AnyCmd",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon")
            ]
        )
    ]
)
