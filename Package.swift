// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PastePaw",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "PastePaw", targets: ["PastePaw"]),
        .library(name: "PastePawCore", targets: ["PastePawCore"])
    ],
    targets: [
        .target(name: "PastePawCore"),
        .executableTarget(
            name: "PastePaw",
            dependencies: ["PastePawCore"],
            exclude: [
                "Resources/AppIcon.iconset",
                "Resources/AppIconPreview.png"
            ],
            resources: [
                .copy("Resources/AppIcon.icns"),
                .copy("Resources/fufu-idle.png"),
                .copy("Resources/PastePawToolBarIcon.png")
            ]
        ),
        .testTarget(
            name: "PastePawCoreTests",
            dependencies: ["PastePawCore"]
        )
    ]
)
