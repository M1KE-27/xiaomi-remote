# XiaomiRemote

A native iOS app that turns your iPhone into a remote control for a Xiaomi TV
(or any Android TV / Google TV device). It talks directly to the TV over
Wi-Fi using the **Android TV Remote v2** protocol — no cloud, no Mi Home
account, no third-party server in between.

Built because I kept losing the physical remote and figured I'd rather write
one than get up and look for it.

## What it does

- **Discovers TVs on the local network** via Bonjour (`_androidtvremote2._tcp`).
- **Pairs with the TV**: implements the "polo" handshake on port `6467` —
  the TV shows a 6-digit code on screen, you type it into the app, and a
  SHA-256 challenge over both devices' certificate keys proves the pairing.
- **Sends remote control input** over a persistent TLS connection on port
  `6466`: power, D-pad, OK, number pad, volume/mute, back/home, the Mi
  button, color keys, input/channel list/settings/teletext, and the
  assistant (mic) button.
- **Launches apps** on the TV via deep link (Netflix and Prime Video
  shortcuts are wired up in the remote UI).
- Auto-reconnects with backoff if the connection drops, and asks iOS for a
  short background grace period so quickly switching apps doesn't kill the
  socket.
- Remembers which TVs you've already paired with (per-host, via
  `UserDefaults`) so reopening the app reconnects silently instead of asking
  to pair again.

## How the protocol works

Android TV Remote v2 authenticates clients with mutual TLS. The app bundles
its own self-signed client identity (`XiaomiRemote/Resources/tv_identity.p12`,
loaded in `TVIdentity.swift`) and uses it for both the pairing handshake and
the ongoing control connection. There's no external protobuf library —
`ProtobufEncoder.swift` is a small hand-rolled encoder that writes just the
varint / length-delimited / message fields this protocol needs, and
`TVRemoteMessages.swift` builds the actual pairing and key-injection frames
on top of it.

## Tech stack

- **Swift 5.9 / SwiftUI**, iOS 16+
- **Network.framework** (`NWConnection`, `NWBrowser`) for TLS sockets and
  Bonjour discovery
- **CryptoKit** / **Security** for the pairing hash and the TLS client
  identity
- **[XcodeGen](https://github.com/yonaskolb/XcodeGen)** — the Xcode project
  is generated from `project.yml`, not checked into git
- **Fastlane** — personal device signing/registration (`fastlane/Fastfile`)
- **GitHub Actions** — CI builds an unsigned IPA on every push to `main`
  and a separate workflow boots the iOS Simulator to capture UI screenshots

There's also a `preview-swift/` folder: a standalone SwiftUI-compatible UI
preview (via [Tokamak](https://github.com/TokamakUI/Tokamak)) compiled to
WebAssembly, so the remote's layout can be iterated on in a browser without
needing a Mac. See `preview-swift/README.md` for setup.

## Requirements

- Xcode 15+ (iOS 16.0 deployment target)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- A Xiaomi TV / Google TV / Android TV device with the Android TV Remote
  service enabled, on the same Wi-Fi network as your iPhone

## Build & run

```bash
git clone https://github.com/M1KE-27/xiaomi-remote.git
cd xiaomi-remote
xcodegen generate
open XiaomiRemote.xcodeproj
```

Then build and run the `XiaomiRemote` scheme on a simulator or device. Code
signing is turned off by default in `project.yml` (`CODE_SIGNING_ALLOWED:
NO`), which is enough to run on the Simulator; to run on a physical iPhone
you'll need to point it at your own Apple ID / team in Xcode's Signing &
Capabilities.

The app needs `XiaomiRemote/Resources/tv_identity.p12` (a bundled TLS client
certificate) to be present to load — it's already committed in this repo.
CI regenerates it from a `TV_P12_BASE64` GitHub Actions secret instead of
using the committed copy.

On first launch, open **Ajustes** (Settings), tap **Buscar dispositivos** to
discover TVs on your network (or enter an IP manually), then **Conectar /
Emparejar** and type the code shown on the TV screen.

> Note: the in-app UI text is in Spanish (the author's language).

## Project structure

```
XiaomiRemote/
  App/                  App entry point
  Models/               TVState (app state/UserDefaults), key code mapping
  Network/               Bonjour discovery, pairing + remote TLS clients,
                          protobuf encoder, message builders, TLS identity
  Views/                Remote, Settings, Pairing screens (SwiftUI)
  Resources/             Bundled TLS client identity (tv_identity.p12)
preview-swift/           Browser-based SwiftUI preview (Tokamak + Wasm)
fastlane/                Personal signing lane
scripts/firmar.sh        Personal sideloading helper (AltServer/Sideloader)
project.yml               XcodeGen project definition
```

## About

I'm 14, self-taught, and football is what I actually do most days — this is
a hobby project I hack on in between. It's built to control my own TV, so
some things (default IP, Spanish UI strings) are tuned for that, but the
protocol implementation should work with any Android TV Remote v2–compatible
device.
