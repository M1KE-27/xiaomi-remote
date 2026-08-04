#!/usr/bin/env bash
# Firma e instala XiaomiRemote en el iPhone con una Apple ID gratis.
# Levanta anisette, espera a que responda y reintenta el login (que falla
# aleatoriamente) hasta que entra. Repite este script para renovar el
# certificado antes de que caduque a los 7 días.
#
# Uso:  ./firmar.sh [ruta_al_ipa]
set -u

APPLE_ID="${APPLE_ID:-iam1ke@proton.me}"
ANISETTE_PORT="${ANISETTE_PORT:-6969}"
SIDELOADER="${SIDELOADER:-$HOME/altserver/sideloader-cli}"
IPA="${1:-build/XiaomiRemote-unsigned/XiaomiRemote-unsigned.ipa}"
RETRIES="${RETRIES:-10}"

green() { printf '\033[32m%s\033[0m\n' "$1"; }
red()   { printf '\033[31m%s\033[0m\n' "$1"; }
info()  { printf '\033[36m%s\033[0m\n' "$1"; }

[ -x "$SIDELOADER" ] || { red "No encuentro sideloader-cli en $SIDELOADER"; exit 1; }
[ -f "$IPA" ]        || { red "No encuentro el IPA en $IPA"; exit 1; }

# 1) Asegurar anisette en marcha (podman/docker)
CONTAINER_TOOL=$(command -v podman 2>/dev/null || command -v docker 2>/dev/null || echo "")
if ! curl -s "http://127.0.0.1:${ANISETTE_PORT}/v3/client_info" >/dev/null 2>&1; then
    info "Levantando servidor anisette..."
    if [ -n "$CONTAINER_TOOL" ]; then
        NAME=$($CONTAINER_TOOL ps -a --format '{{.Names}}' | grep -i anisette | head -1)
        if [ -n "$NAME" ]; then
            $CONTAINER_TOOL start "$NAME" >/dev/null
        else
            $CONTAINER_TOOL run -d --name anisette -p ${ANISETTE_PORT}:6969 \
                dadoum/anisette-v3-server >/dev/null
        fi
    fi
    info "Esperando a anisette..."
    for _ in $(seq 1 15); do
        curl -s "http://127.0.0.1:${ANISETTE_PORT}/v3/client_info" >/dev/null 2>&1 && break
        sleep 1
    done
fi
export SIDELOADER_ANISETTE_SERVER="http://127.0.0.1:${ANISETTE_PORT}"
export ALTSERVER_ANISETTE_SERVER="http://127.0.0.1:${ANISETTE_PORT}"

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

# 3) Reintentar instalación con AltServer
info "Ejecutando AltServer para instalar en el iPhone..."
OUT_LOG=$(mktemp)

CMD_PASS=""
if [ -n "${APPLE_PASS:-}" ]; then
    CMD_PASS="-p $APPLE_PASS"
fi

for i in $(seq 1 "$RETRIES"); do
    info "=== Intento $i/$RETRIES ==="
    : > "$OUT_LOG"
    if [ -n "$CMD_PASS" ]; then
        "$SIDELOADER" -u "$UDID" -a "$APPLE_ID" $CMD_PASS "$IPA" 2>&1 | tee "$OUT_LOG"
    else
        "$SIDELOADER" -u "$UDID" -a "$APPLE_ID" "$IPA" 2>&1 | tee "$OUT_LOG"
    fi
    
    if ! grep -q -E "(Could not install|Error:|-22406|Exception:)" "$OUT_LOG" && grep -q -E "(Finished!|Installed)" "$OUT_LOG"; then
        green "¡Instalado con éxito! Confía en el perfil en Ajustes › General › VPN y gestión de dispositivos."
        rm -f "$OUT_LOG"
        exit 0
    fi
    info "El intento falló (error de autenticación/2FA o timeout). Reintentando en 3s..."
    sleep 3
done

rm -f "$OUT_LOG"
red "No se pudo instalar tras $RETRIES intentos. Revisa tu contraseña de Apple ID o código 2FA."
exit 1
