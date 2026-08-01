# pangolin-plus components (single product)

This directory is the **ecosystem half of pangolin-plus**. We do **not** ship separate
`newt-plus` / `olm-plus` products. We **mine** upstream [fosrl](https://github.com/fosrl)
repos (and any useful fork PRs), apply plus deltas here, and build one distribution.

| Component | Upstream | Base tag | Plus status |
|-----------|----------|----------|-------------|
| **newt/** | [fosrl/newt](https://github.com/fosrl/newt) | **1.15.0** | **Mined** — registration chain, reconnect WgData, healthcheck races, TLS ConnectionState, prefer-local-routes default |
| **gerbil/** | [fosrl/gerbil](https://github.com/fosrl/gerbil) | **1.4.3** | **Mined** — remoteConfigURL sanitize, Stop stopOnce |
| **olm/** | [fosrl/olm](https://github.com/fosrl/olm) | **1.8.1** | **Mined** — always re-register on WS reconnect |
| **badger/** | [fosrl/badger](https://github.com/fosrl/badger) | **v1.5.0** | **Mined** — trusted-hop real-IP headers + unit tests |
| *(server root)* | [fosrl/pangolin](https://github.com/fosrl/pangolin) | **1.21.1** | **Mined** — see [PANGOLIN_PLUS.md](../PANGOLIN_PLUS.md) |

Nested `.git` dirs are removed so history is the single product `main` branch on [88plug/pangolin-plus](https://github.com/88plug/pangolin-plus).

### Who publishes what

| Piece | Upstream ships | Plus ships / builds |
|-------|----------------|---------------------|
| Pangolin server images | `fosrl/pangolin:*` (GHCR/Docker Hub) | **`ghcr.io/88plug/pangolin-plus/pangolin:TAG`** or `make plus-images` → local |
| Gerbil images | `fosrl/gerbil:*` | **`ghcr.io/88plug/pangolin-plus/gerbil:TAG`** / local |
| Newt images/binaries | `fosrl/newt` + `get-newt.sh` | **Releases + `scripts/get-plus-newt.sh`** / local |
| Olm images/binaries | `fosrl/olm` + desktop apps on pangolin.net | **Releases + `scripts/get-plus-olm.sh`** / local |
| Badger | Traefik plugin catalog / git tag | `components/badger` as **localPlugins** (not a long-running image) |

Stock clients work against a plus **server**, but you **must** run plus-built newt/olm (and monorepo badger localPlugins) to get the mined client/plugin fixes in the table above. Binary names stay `newt` / `olm` / `gerbil`; published images are `ghcr.io/88plug/pangolin-plus/*`.

### User install (published)

```bash
export TAG=v1.21.1-plus
docker pull ghcr.io/88plug/pangolin-plus/newt:${TAG}
curl -fsSL https://raw.githubusercontent.com/88plug/pangolin-plus/main/scripts/get-plus-newt.sh | sh
curl -fsSL https://raw.githubusercontent.com/88plug/pangolin-plus/main/scripts/get-plus-olm.sh | sh
```

### Build (from repo root)

```bash
# Go binaries → components/*/bin/
make components-build
make components-test

# Multi-OS release assets → dist/plus/ (newt_*, olm_*, gerbil_*)
# make plus-release-binaries VERSION=1.21.1-plus

# Local Docker images (pangolin-plus/*:local)
make plus-images
# Optional registry push (explicit registry required; refuses fosrl/*):
# make plus-images-push PLUS_REGISTRY=ghcr.io/88plug/pangolin-plus PLUS_TAG=1.21.1-plus

# Or compose contexts:
docker compose -f compose.plus.yaml build
docker compose -f compose.plus.yaml up -d
# Lab site connector (requires NEWT_ID + NEWT_SECRET; restart policy is "no"):
# NEWT_ID=... NEWT_SECRET=... docker compose -f compose.plus.yaml --profile lab up -d

# Guards + syntax/config smoke (no full image rebuild):
# make plus-guards-selftest
# make plus-verify
```

| Target | Output |
|--------|--------|
| `make components-build` | `newt`, `gerbil`, `olm` binaries under `components/*/bin/` |
| `make plus-release-binaries VERSION=…` | Multi-OS assets under `dist/plus/` (+ SHA256SUMS) |
| `make plus-images` | Docker tags `pangolin-plus/{pangolin,gerbil,newt,olm}:local` |
| `make -C components/olm local` | User client only (not a compose service) |
| badger | Plugin source — `compose.plus` bind-mounts + deploy copies as Traefik `localPlugins` |
| `make plus-guards-selftest` | Guard smoke + compose config + ansible syntax-check |

**Published path:** tag `vX.Y.Z-plus` → `.github/workflows/plus-release.yml` (GHCR multi-arch + Release assets).

**fosrl stock fallback (deploy):** set `pangolin_image=fosrl/pangolin:1.21.1`, `gerbil_image=fosrl/gerbil:latest`, `pull_images=true`. See [deploy/README.md](../deploy/README.md).

### Provenance of newt deltas

Mined open/closed PRs: #424, #413, #412, #357; #414 intent → `PreferLocalRoutes` default true.
Details: [newt/NEWT_PLUS.md](newt/NEWT_PLUS.md) (component changelog).
