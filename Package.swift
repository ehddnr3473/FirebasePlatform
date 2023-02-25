// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FirebasePlatform",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "FirebasePlatform",
            targets: ["FirebasePlatform"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            .upToNextMajor(from: "9.0.0")
        ),
        .package(
            url: "https://github.com/ehddnr3473/Domain.git",
            .upToNextMajor(from: "0.0.7")
        )
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "FirebasePlatform",
            dependencies: [
                .product(
                    name: "FirebaseFirestore",
                    package: "firebase-ios-sdk"
                ),
                .product(
                    name: "FirebaseStorage",
                    package: "firebase-ios-sdk"
                ),
                .product(
                    name: "Domain",
                    package: "Domain"
                )
            ],
            path: "./Sources"
        )
    ]
)
