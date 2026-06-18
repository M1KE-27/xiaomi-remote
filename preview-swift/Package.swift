// swift-tools-version:5.9
import PackageDescription

// Preview interactivo de la UI en el navegador (SwiftUI -> WebAssembly).
// Toolchain: Swift + SDK de WebAssembly de SwiftWasm.  Arrancar con:
//     swift run carton dev
// y abrir http://127.0.0.1:8080
let package = Package(
    name: "XiaomiRemotePreview",
    platforms: [.macOS(.v11)],
    dependencies: [
        .package(url: "https://github.com/TokamakUI/Tokamak", from: "0.11.1"),
        .package(url: "https://github.com/swiftwasm/carton", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "XiaomiRemotePreview",
            dependencies: [
                .product(name: "TokamakShim", package: "Tokamak"),
            ]
        ),
    ]
)
