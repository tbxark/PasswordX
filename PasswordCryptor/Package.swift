// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "PasswordCryptor",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(name: "PasswordCryptor", targets: ["PasswordCryptor"]),
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.8.0"),
    ],
    targets: [
        .target(name: "PasswordCryptor", dependencies: [
            .product(name: "CryptoSwift", package: "CryptoSwift"),
        ]),
        .testTarget(name: "PasswordCryptorTests", dependencies: ["PasswordCryptor"]),
    ]
)
