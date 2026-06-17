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
