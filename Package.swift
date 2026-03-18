// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TravelApp",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "TravelApp",
            targets: ["TravelApp"]
        ),
    ],
    targets: [
        .target(
            name: "TravelApp",
            path: "TravelApp"
        ),
    ]
)
