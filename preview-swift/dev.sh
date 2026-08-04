#!/usr/bin/env bash
# Preview en vivo de la UI Swift en el navegador.
# Compila a WebAssembly con el plugin PackageToJS (SDK oficial) y, al guardar un
# .swift, recompila y recarga el navegador (~unos segundos por cambio).
#
# Uso:   ./dev.sh
# Abre:  http://127.0.0.1:8080   (o el Simple Browser de VS Code en esa URL)
set -u
cd "$(dirname "$0")"

SDK="${SDK:-swift-6.3.2-RELEASE_wasm}"
PORT="${PORT:-8080}"
OUT=".build/plugins/PackageToJS/outputs/Package"

command -v swift >/dev/null || { echo "❌ Swift no está en el PATH (usa tu terminal del host, no la de VS Code)."; exit 1; }
swift sdk list 2>/dev/null | grep -q "$SDK" || { echo "❌ Falta el SDK '$SDK'. Instálalo (ver README)."; exit 1; }

inject_reload() {
  [ -f "$OUT/index.html" ] || return
  grep -q "__autoreload__" "$OUT/index.html" 2>/dev/null && return
  cat >> "$OUT/index.html" <<'HTML'
<script>/*__autoreload__*/let __l;setInterval(async()=>{try{let t=await(await fetch("/__reload__?"+Date.now())).text();if(__l&&t!==__l)location.reload();__l=t;}catch(e){}},1000)</script>
HTML
}

build() {
  echo "🔨 $(date +%H:%M:%S) compilando a wasm..."
  # El SDK oficial de WASI exige flags para mman/signal/clocks que Tokamak no pone.
  if swift package --swift-sdk "$SDK" --disable-sandbox \
      -Xcc -D_WASI_EMULATED_MMAN -Xcc -D_WASI_EMULATED_SIGNAL -Xcc -D_WASI_EMULATED_PROCESS_CLOCKS \
      -Xlinker -lwasi-emulated-mman -Xlinker -lwasi-emulated-signal -Xlinker -lwasi-emulated-process-clocks \
      js --use-cdn; then
    inject_reload
    date +%s%N > "$OUT/__reload__"
    echo "✅ listo"
  else
    echo "⚠️  error de compilación (arriba). Corrige y guarda."
  fi
}

build
[ -f "$OUT/index.html" ] || { echo "❌ PackageToJS no generó index.html. Pega el error de arriba."; exit 1; }

( cd "$OUT" && python3 -m http.server "$PORT" >/dev/null 2>&1 ) &
SRV=$!
trap "kill $SRV 2>/dev/null" EXIT
echo ""
echo "🌐 Preview en:  http://127.0.0.1:$PORT"
echo "   (En VS Code: Cmd/Ctrl+Shift+P -> 'Simple Browser: Show' -> esa URL)"
echo "   Guarda cualquier .swift y se recarga solo. Ctrl+C para salir."
echo ""

lastsum=""
while true; do
  if command -v inotifywait >/dev/null 2>&1; then
    inotifywait -qq -r -e modify,create,delete,move Sources 2>/dev/null
    build
  else
    sum=$(find Sources -type f -name '*.swift' -exec stat -c '%Y %n' {} + 2>/dev/null | sort | md5sum)
    if [ "$sum" != "$lastsum" ]; then
      [ -n "$lastsum" ] && build
      lastsum="$sum"
    fi
    sleep 1
  fi
done
