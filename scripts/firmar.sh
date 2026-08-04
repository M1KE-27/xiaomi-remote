#!/usr/bin/env bash
# Firma e instala XiaomiRemote en el iPhone con una Apple ID gratis.
# Levanta anisette, espera a que responda y reintenta el login (que falla
# aleatoriamente) hasta que entra. Repite este script para renovar el
# certificado antes de que caduque a los 7 días.
#
# Uso:  ./firmar.sh [ruta_al_ipa]
set -u

APPLE_ID="${APPLE_ID:?set APPLE_ID env var}"
ANISETTE_PORT="${ANISETTE_PORT:-6969}"
SIDELOADER="${SIDELOADER:-$HOME/altserver/sideloader-cli}"
IPA="${1:-$HOME/Descargas/XiaomiRemote-unsigned.ipa}"
RETRIES="${RETRIES:-10}"

green() { printf '\033[32m%s\033[0m\n' "$1"; }
red()   { printf '\033[31m%s\033[0m\n' "$1"; }
info()  { printf '\033[36m%s\033[0m\n' "$1"; }

[ -x "$SIDELOADER" ] || { red "No encuentro sideloader-cli en $SIDELOADER"; exit 1; }
[ -f "$IPA" ]        || { red "No encuentro el IPA en $IPA"; exit 1; }

# 1) Asegurar anisette en marcha (podman)
if ! curl -s "http://127.0.0.1:${ANISETTE_PORT}/v3/client_info" >/dev/null 2>&1; then
    info "Levantando servidor anisette..."
    NAME=$(podman ps -a --format '{{.Names}}' | grep -i anisette | head -1)
    if [ -n "$NAME" ]; then
        podman start "$NAME" >/dev/null
    else
        podman run -d --name anisette -p ${ANISETTE_PORT}:6969 \
            dadoum/anisette-v3-server >/dev/null
    fi
    info "Esperando a anisette..."
    for _ in $(seq 1 30); do
        curl -s "http://127.0.0.1:${ANISETTE_PORT}/v3/client_info" >/dev/null 2>&1 && break
        sleep 1
    done
fi
curl -s "http://127.0.0.1:${ANISETTE_PORT}/v3/client_info" >/dev/null 2>&1 \
    && green "anisette OK" || { red "anisette no responde"; exit 1; }

# 2) Detectar iPhone
UDID=$(idevice_id -l 2>/dev/null | head -1)
[ -n "$UDID" ] || { red "No se detecta ningún iPhone por USB"; exit 1; }
green "iPhone detectado: $UDID"

export SIDELOADER_ANISETTE_SERVER="http://127.0.0.1:${ANISETTE_PORT}"

# 2.5) Parchear __LINKEDIT: en iOS 26/27 beta el dyld exige vmsize >= filesize.
#      El binario sin firmar deja poco margen y, al añadir Sideloader la firma,
#      filesize se pasa de vmsize y dyld mata la app al arrancar ("segment
#      '__LINKEDIT' filesize exceeds vmsize"). Agrandamos vmsize antes de firmar.
info "Parcheando __LINKEDIT (margen para la firma)..."
WORK=$(mktemp -d)
( cd "$WORK" && unzip -oq "$IPA" )
APPBIN=$(find "$WORK/Payload" -maxdepth 2 -type f -path '*.app/*' \
            ! -name '*.*' -perm -u+x | head -1)
if [ -n "$APPBIN" ] && python3 - "$APPBIN" <<'PY'
import struct,sys
p=sys.argv[1]; d=bytearray(open(p,'rb').read())
def u32(o): return struct.unpack_from('<I',d,o)[0]
if u32(0)!=0xfeedfacf: sys.exit(0)        # solo Mach-O arm64 thin
ncmds=u32(16); off=32; TARGET=0x40000
for _ in range(ncmds):
    cmd=u32(off); csize=u32(off+4)
    if cmd==0x19 and bytes(d[off+8:off+24]).split(b'\0')[0]==b'__LINKEDIT':
        vm=struct.unpack_from('<Q',d,off+32)[0]; fs=struct.unpack_from('<Q',d,off+48)[0]
        newvm=max(TARGET, (fs+0x20000+0x3fff)&~0x3fff)
        if vm<newvm:
            struct.pack_into('<Q',d,off+32,newvm); open(p,'wb').write(d)
            print("  __LINKEDIT vmsize %#x -> %#x"%(vm,newvm))
        break
    off+=csize
PY
then
    PATCHED="$WORK/patched.ipa"
    ( cd "$WORK" && zip -qr "$PATCHED" Payload )
    IPA="$PATCHED"
    green "IPA parcheado listo."
else
    info "(no se pudo parchear, sigo con el IPA original)"
fi

# 3) Reintentar instalación: sideloader pide Apple ID/contraseña/2FA por terminal.
#    El login da -22406 de forma aleatoria; reintentamos hasta que entra.
info "Sideloader pedirá tu Apple ID, contraseña y (si toca) el código 2FA del iPhone."
for i in $(seq 1 "$RETRIES"); do
    info "=== Intento $i/$RETRIES ==="
    if "$SIDELOADER" install --udid "$UDID" "$IPA" -i; then
        green "¡Instalado! Confía en el perfil en Ajustes › General › VPN y gestión de dispositivos."
        exit 0
    fi
    info "Reintentando en 4s (el fallo de login suele ser aleatorio)..."
    sleep 4
done

red "No se pudo instalar tras $RETRIES intentos. Revisa contraseña/2FA y vuelve a ejecutar."
exit 1
