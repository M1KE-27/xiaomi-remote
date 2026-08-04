# Preview interactivo de la UI (SwiftUI → WebAssembly)

Renderiza la interfaz del mando en el navegador, escrita en **Swift de verdad**
(vía [Tokamak](https://github.com/TokamakUI/Tokamak), API compatible con SwiftUI)
y compilada a WebAssembly con [carton](https://github.com/swiftwasm/carton).
Recarga en caliente: editas un `.swift` y el navegador se actualiza solo.

> Limitaciones del navegador (no del iPhone): no hay **SF Symbols** (los iconos
> van como unicode/emoji), ni háptica, ni los gestos touch-down. Para fidelidad
> 1:1 del render de iOS hace falta macOS. Esto es para **iterar el diseño rápido**.

## Requisitos (en tu terminal de Fedora, no en el sandbox)

1. **Swift** (6.x recomendado):
   ```bash
   # opción A: paquete de Fedora
   sudo dnf install swiftlang
   # opción B: swiftly (gestor oficial)
   curl -O https://download.swift.org/swiftly/linux/swiftly-$(uname -m).tar.gz
   tar zxf swiftly-$(uname -m).tar.gz && ./swiftly init
   . ~/.local/share/swiftly/env.sh && swiftly install latest
   swift --version
   ```

2. **SDK oficial de WebAssembly de swift.org** que COINCIDA con tu Swift.
   ⚠️ En Fedora NO sirve la toolchain de SwiftWasm (solo trae binarios para
   Ubuntu/Amazon Linux). Usa el SDK oficial (agnóstico de distro). Para 6.3.2:
   ```bash
   swift sdk install https://download.swift.org/swift-6.3.2-release/wasm-sdk/swift-6.3.2-RELEASE/swift-6.3.2-RELEASE_wasm.artifactbundle.tar.gz --checksum a61f0584c93283589f8b2f42db05c1f9a182b506c2957271402992655591dd7c
   swift sdk list   # -> swift-6.3.2-RELEASE_wasm
   ```
   Para otra versión de Swift, mira la URL en
   https://www.swift.org/documentation/articles/wasm-getting-started.html

## Arrancar el preview

```bash
cd preview-swift
# IMPORTANTE: apuntar a ese SDK para que carton no baje la toolchain de Ubuntu
swift run carton dev --swift-sdk swift-6.3.2-RELEASE_wasm
# abre http://127.0.0.1:8080
```

Si Tokamak 0.11.1 no compila con Swift 6.3, dímelo con el error y subo el pin
de Tokamak en `Package.swift`.

## Estructura

- `Sources/XiaomiRemotePreview/App.swift` — entrada + selector Remote/Ajustes.
- `RemotePreview.swift` — el mando (misma disposición que `RemoteView.swift` del app).
- `SettingsPreview.swift` — pantalla de ajustes.
- `MockTV.swift` — controlador simulado (sin red); muestra la última tecla.
