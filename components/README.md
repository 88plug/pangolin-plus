# Components

Mined companions for **pangolin-plus**. Not separate `*-plus` products — one monorepo, one release.

| Dir | Upstream | Base | What’s mined |
|-----|----------|------|----------------|
| [newt/](newt/) | [fosrl/newt](https://github.com/fosrl/newt) | 1.15.0 | Registration chain, reconnect WgData, health races, TLS state, prefer-local-routes **on** |
| [gerbil/](gerbil/) | [fosrl/gerbil](https://github.com/fosrl/gerbil) | 1.4.3 | remoteConfig URL sanitize, Stop once |
| [olm/](olm/) | [fosrl/olm](https://github.com/fosrl/olm) | 1.8.1 | Re-register on every WS reconnect |
| [badger/](badger/) | [fosrl/badger](https://github.com/fosrl/badger) | v1.5.0 | Trusted-hop real-IP headers + tests |

Server root (parent dir) = mined fosrl/pangolin — see [PANGOLIN_PLUS.md](../PANGOLIN_PLUS.md).

## Run what you built

Release images and install scripts ship **these** trees (not stock `fosrl/*`).

```bash
# From repo root
make components-build          # → components/*/bin/
make components-test
make plus-images               # → pangolin-plus/*:local
make plus-release-binaries VERSION=1.21.1-plus   # → dist/plus/
```

Users: [README.md](../README.md) · published: `ghcr.io/88plug/pangolin-plus/*` + [Releases](https://github.com/88plug/pangolin-plus/releases).

Newt provenance notes: [newt/NEWT_PLUS.md](newt/NEWT_PLUS.md).
