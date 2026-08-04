// swift-tools-version:6.0
import PackageDescription

// Preview de la UI en el navegador (SwiftUI -> WebAssembly) usando el SDK
// oficial de WebAssembly + el plugin PackageToJS de JavaScriptKit (sustituye a
// carton, que fue archivado). Construir/servir con ./dev.sh
let package = Package(
    name: "XiaomiRemotePreview",
    platforms: [.macOS(.v11)],
    dependencies: [
        .package(url: "https://github.com/TokamakUI/Tokamak", from: "0.11.1"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit", from: "0.19.0"),
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
