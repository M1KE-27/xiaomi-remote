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

2. **SDK de WebAssembly** que coincida con tu versión de Swift. Mira la release
   correspondiente en https://github.com/swiftwasm/swift/releases y:
   ```bash
   swift sdk install <URL-del-artifactbundle-wasm-de-tu-versión>
   swift sdk list   # debe aparecer un target wasm32-unknown-wasi
   ```

## Arrancar el preview

```bash
cd preview-swift
swift run carton dev
# abre http://127.0.0.1:8080
```

Si `carton` se queja por versiones de Tokamak/Swift, dímelo con el error y
ajustamos los pins en `Package.swift` (Tokamak 0.11.x ↔ Swift 5.9 / 6.0).

## Estructura

- `Sources/XiaomiRemotePreview/App.swift` — entrada + selector Remote/Ajustes.
- `RemotePreview.swift` — el mando (misma disposición que `RemoteView.swift` del app).
- `SettingsPreview.swift` — pantalla de ajustes.
- `MockTV.swift` — controlador simulado (sin red); muestra la última tecla.
