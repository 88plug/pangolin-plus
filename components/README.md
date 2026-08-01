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

| Piece | Upstream ships | Plus builds |
|-------|----------------|-------------|
| Pangolin server images | `fosrl/pangolin:*` (GHCR/Docker Hub) | `make plus-images` → `pangolin-plus/pangolin:local` |
| Gerbil images | `fosrl/gerbil:*` | `pangolin-plus/gerbil:local` |
| Newt images/binaries | `fosrl/newt` + install scripts | `components/newt/bin/newt` or `pangolin-plus/newt:local` |
| Olm images/binaries | `fosrl/olm` + desktop apps on pangolin.net | `components/olm/bin/olm` or `pangolin-plus/olm:local` |
| Badger | Traefik plugin catalog / git tag | `components/badger` as **localPlugins** (not a long-running image) |

Stock clients work against a plus **server**, but you **must** run plus-built newt/olm (and monorepo badger localPlugins) to get the mined client/plugin fixes in the table above. Binary names stay `newt` / `olm` / `gerbil`; image tags are `pangolin-plus/*` (or your registry).

### Build (from repo root)

```bash
# Go binaries → components/*/bin/
make components-build
make components-test

# Local Docker images (pangolin-plus/*:local)
make plus-images
# Optional registry push (explicit registry required; refuses fosrl/*):
# make plus-images-push PLUS_REGISTRY=ghcr.io/you/pangolin-plus PLUS_TAG=local

# Or compose contexts:
docker compose -f compose.plus.yaml build
docker compose -f compose.plus.yaml up -d
# Lab site connector (requires NEWT_ID + NEWT_SECRET; restart policy is "no"):
# NEWT_ID=... NEWT_SECRET=... docker compose -f compose.plus.yaml --profile lab up -d
```

| Target | Output |
|--------|--------|
| `make components-build` | `newt`, `gerbil`, `olm` binaries under `components/*/bin/` |
| `make plus-images` | Docker tags `pangolin-plus/{pangolin,gerbil,newt,olm}:local` |
| `make -C components/olm local` | User client only (not a compose service) |
| badger | Plugin source only — deploy playbooks mount as Traefik `localPlugins` |

**fosrl stock fallback (deploy):** set `pangolin_image=fosrl/pangolin:1.21.1`, `gerbil_image=fosrl/gerbil:latest`, `pull_images=true`. See [deploy/README.md](../deploy/README.md).

### Provenance of newt deltas

Mined open/closed PRs: #424, #413, #412, #357; #414 intent → `PreferLocalRoutes` default true.
Details: [newt/NEWT_PLUS.md](newt/NEWT_PLUS.md) (component changelog).
