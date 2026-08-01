# pangolin-plus

A community **plus fork** of the **Pangolin self-host stack** — not just the dashboard server.
One monorepo product that **mines** [fosrl/pangolin](https://github.com/fosrl/pangolin), [newt](https://github.com/fosrl/newt), [gerbil](https://github.com/fosrl/gerbil), [olm](https://github.com/fosrl/olm), and [badger](https://github.com/fosrl/badger) (and useful fork PRs), then ships **one** distribution.

> **The bar for every change:** one a thoughtful upstream maintainer would accept — small, focused, tested, verified before it ships. Product home: **[88plug/pangolin-plus](https://github.com/88plug/pangolin-plus)** (`main`). Upstream [fosrl/pangolin](https://github.com/fosrl/pangolin) is remote **`upstream`** for sync/port only. Nothing here is a throwaway hack. We do **not** publish separate `newt-plus` / `olm-plus` products.

**Layout**

| Path | Role | Base | Plus status |
|------|------|------|-------------|
| *(repo root)* | Pangolin CE server | **1.21.1** | **Mined** |
| [`components/newt/`](components/newt/) | Site connector | **1.15.0** | **Mined** |
| [`components/gerbil/`](components/gerbil/) | WireGuard interface mgr | **1.4.3** | **Mined** |
| [`components/olm/`](components/olm/) | Client | **1.8.1** | **Mined** |
| [`components/badger/`](components/badger/) | Traefik auth middleware | **v1.5.0** | **Mined** |
| [`deploy/`](deploy/) | Ansible + ops notes | — | Own work |
| [`compose.plus.yaml`](compose.plus.yaml) | Build full stack from this tree | — | Own work |

---

## Why a plus fork?

Upstream Pangolin is a **multi-binary edge** (server + newt + gerbil + olm + badger). Plusing only the server leaves site connectivity and clients broken in the real world. This fork is the **single** place those graveyards get mined into one coherent CE self-host distribution.

So pangolin-plus is:
1. **A daily-driver self-host stack** — controller, connector, WG helper, client sources, Badger, deploy glue.
2. **A proving ground for upstream** — each component delta is a port candidate back to the matching fosrl repo.

---

## How we're different — at a glance

### Server (repo root · fosrl/pangolin 1.21.1)

| Pillar | upstream CE | pangolin-plus |
|---|---|---|
| BYOC / CF Origin TLS | Resolver name only | **PEM upload API + UI** ([#3243](https://github.com/fosrl/pangolin/issues/3243)) |
| WG site routing | Targets only | **tunnelProfile + routingMode** full-tunnel/selective |
| Sessions / audit / geoblock / OIDC | Open PR gaps | **Mined open + closed-unmerged PRs** (see bug matrix) |
| Response headers | Request only | **Request + response** ([#3172](https://github.com/fosrl/pangolin/pull/3172)) |
| Tests | Ad-hoc | **`npm test` runner** ([#3368](https://github.com/fosrl/pangolin/pull/3368)) |

### Newt (`components/newt` · fosrl/newt 1.15.0)

| Pillar | upstream | plus |
|---|---|---|
| WG registration chain | Can drop pending after compat re-reg | **Preserve chain** ([#424](https://github.com/fosrl/newt/pull/424) / [#423](https://github.com/fosrl/newt/issues/423)) |
| Reconnect health | Stale hcStatus | **Fresh WgData** ([#413](https://github.com/fosrl/newt/pull/413) / [#411](https://github.com/fosrl/newt/issues/411)) |
| Healthcheck races | Unguarded fields | **Mutex guards** ([#412](https://github.com/fosrl/newt/pull/412)) |
| netstack TLS | No ConnectionState | **Forwarded** ([#357](https://github.com/fosrl/newt/pull/357) ⚡) |
| LAN vs tunnel | PreferLocalRoutes off by default | **Default on** ([#414](https://github.com/fosrl/newt/pull/414) intent) |

### Gerbil / Olm / Badger (mined in-tree)

| Component | Base | Plus status |
|---|---|---|
| Gerbil | 1.4.3 tree | **Mined** — URL sanitize + idempotent Stop |
| Olm | 1.8.1 tree | **Mined** — always re-register on WS reconnect |
| Badger | v1.5.0 tree | **Mined** — trusted-hop X-Real-IP / XFF chain + unit tests |

---

## Headline additions

**Server**
- PEM certificate upload (OSS BYOC) · tunnel profiles · OIDC open-redirect guard · custom response headers · audit/session/geoblock/API graveyard ports · `deploy/` Ansible · `npm test`

**Newt (in-tree)**
- Registration chain · reconnect WgData · healthcheck races · TLS ConnectionState · prefer-local-routes default true

**Gerbil / Olm / Badger (in-tree)**
- remoteConfigURL path sanitize (bandwidth 400s) · Stop() stopOnce · olm WS re-register · badger real-IP header chain

**Distribution**
- **Published:** `ghcr.io/88plug/pangolin-plus/{pangolin,gerbil,newt,olm}` + GitHub Release binaries on tags `vX.Y.Z-plus` (workflow: `.github/workflows/plus-release.yml`)
- `compose.plus.yaml` builds pangolin + gerbil; uses `traefik_config.plus.yml` + monorepo badger localPlugins (`compose.example` keeps stock catalog config); newt profile `lab` restart `"no"`
- `make components-build` → newt + gerbil + olm binaries; `make plus-images` → `pangolin-plus/*:local`; `make plus-release-binaries VERSION=…` → `dist/plus/`
- Install scripts: `scripts/get-plus-newt.sh` / `scripts/get-plus-olm.sh` (stock: fosrl `get-*.sh` or `REPO=fosrl/newt`)
- Ansible `deploy/` defaults to plus local tags + monorepo badger localPlugins; GHCR or fosrl via image overrides
- Traefik pin: **v3.7** (compose + deploy + installer)
- **Installer (`install/`) remains stock** fosrl images + catalog badger — use compose.plus / deploy / GHCR for plus

---

## Who publishes what vs what plus builds

| Artifact | Upstream (fosrl / pangolin.net) | pangolin-plus monorepo |
|----------|----------------------------------|------------------------|
| Server image | `fosrl/pangolin:1.21.1` | **`ghcr.io/88plug/pangolin-plus/pangolin:TAG`** or `make plus-images` → `pangolin-plus/pangolin:local` |
| Gerbil image | `fosrl/gerbil:latest` | **`ghcr.io/88plug/pangolin-plus/gerbil:TAG`** / local |
| Newt | Docker Hub + `get-newt.sh` | **GitHub Releases** / `get-plus-newt.sh` / `pangolin-plus/newt:local` |
| Olm | Docker Hub + desktop apps | **GitHub Releases** / `get-plus-olm.sh` / local binary |
| Badger | Traefik plugin catalog / git tag | `components/badger` as Traefik **localPlugins** (not a release binary) |

**Full plus stack:** pull GHCR images (or build from this tree) and run plus newt/olm on site/user hosts; deploy mounts monorepo badger.  
**Stock clients:** fine for smoke tests against a plus server, but **you will not get mined newt/olm/badger fixes** until those hosts run plus-built binaries / monorepo localPlugins.

**Maintainer cut a release:** `git tag v1.21.1-plus && git push origin v1.21.1-plus` → plus-release workflow. After first GHCR push, set each package (`pangolin`/`gerbil`/`newt`/`olm`) visibility to **Public** for anonymous pull. Binary release still publishes if the images job fails.

**fosrl deploy fallback:** `pangolin_image=fosrl/pangolin:1.21.1` `gerbil_image=fosrl/gerbil:latest` `pull_images=true` (guard keys on image **names**, not `image_registry`).
---

## Feature matrix

✓ = present · ◑ = partial · – = absent

| Capability | upstream CE stack | pangolin-plus monorepo |
|---|:--:|:--:|
| Pangolin CE server 1.21.x | ✓ | ✓ + plus deltas |
| Newt connector 1.15.x | ✓ (separate repo) | ✓ **in-tree + mined** |
| Gerbil / Olm / Badger sources | separate | ✓ **in-tree + mined** |
| PEM BYOC upload (OSS) | – | ✓ |
| WG tunnel profiles | – | ✓ |
| Newt reconnect/health correctness pack | open PRs | ✓ mined |
| Prefer local LAN over tunnel routes | flag off | ✓ default on |
| Single compose build of plus images | – | ✓ `compose.plus.yaml` + `make plus-images` |
| Ansible image vars (plus or fosrl) | – | ✓ `deploy/` |

---

## Bug matrix (server + newt)

### Server (fosrl/pangolin)

| Area | Upstream # | Fix |
|---|---|---|
| Sessions | [#3445](https://github.com/fosrl/pangolin/pull/3445) | stripDuplicateSessions first-valid only |
| Audit | [#3459](https://github.com/fosrl/pangolin/pull/3459) / [#3458](https://github.com/fosrl/pangolin/issues/3458) | Ordering |
| Audit | [#3443](https://github.com/fosrl/pangolin/pull/3443) | Filter-attribute 6→1 |
| Integration API | [#3510](https://github.com/fosrl/pangolin/pull/3510) / [#2743](https://github.com/fosrl/pangolin/issues/2743) | Site-resource lookup |
| Geoblock | [#3474](https://github.com/fosrl/pangolin/pull/3474) / [#3432](https://github.com/fosrl/pangolin/issues/3432) | Multi-country COUNTRY_IS_NOT |
| Blueprints | [#3199](https://github.com/fosrl/pangolin/pull/3199) / [#2937](https://github.com/fosrl/pangolin/issues/2937) | Cert UNIQUE upsert |
| Traefik | [#3191](https://github.com/fosrl/pangolin/pull/3191) | Hot-path / wildcard |
| i18n | [#3509](https://github.com/fosrl/pangolin/pull/3509) / [#3480](https://github.com/fosrl/pangolin/issues/3480) | Regional locale |
| SSO | [#3411](https://github.com/fosrl/pangolin/pull/3411) ⚡ / [#3001](https://github.com/fosrl/pangolin/issues/3001) | Resource redirect after expiry |
| Badger | [#3278](https://github.com/fosrl/pangolin/pull/3278) ⚡ | Remote-Groups header |
| OIDC | [#3335](https://github.com/fosrl/pangolin/issues/3335) | Open-redirect guard |

### Newt (fosrl/newt → components/newt)

| Area | Upstream # | Fix |
|---|---|---|
| Registration | [#424](https://github.com/fosrl/newt/pull/424) / [#423](https://github.com/fosrl/newt/issues/423) | Pending chain preserved |
| Reconnect | [#413](https://github.com/fosrl/newt/pull/413) / [#411](https://github.com/fosrl/newt/issues/411) | Fresh WgData |
| Healthcheck | [#412](https://github.com/fosrl/newt/pull/412) | Race guards |
| netstack | [#357](https://github.com/fosrl/newt/pull/357) ⚡ | TLS ConnectionState |
| Routes | [#414](https://github.com/fosrl/newt/pull/414) ⚡ intent | PreferLocalRoutes default true |

### Gerbil (fosrl/gerbil → components/gerbil)

| Area | Upstream # | Fix |
|---|---|---|
| Bandwidth report 400 | [#106](https://github.com/fosrl/gerbil/pull/106) / [#82](https://github.com/fosrl/gerbil/issues/82) | Strip get-config / receive-bandwidth / trailing path from remoteConfigURL |
| Double Stop panic | [#105](https://github.com/fosrl/gerbil/pull/105) / [#51](https://github.com/fosrl/gerbil/issues/51) | `stopOnce` around UDPProxyServer.Stop |

### Olm (fosrl/olm → components/olm)

| Area | Upstream # | Fix |
|---|---|---|
| Reconnect stuck unregistered | [#123](https://github.com/fosrl/olm/pull/123) ⚡ closed-unmerged | Always re-register on every WebSocket OnConnect |

### Badger (fosrl/badger → components/badger)

| Area | Upstream # / fork | Fix |
|---|---|---|
| Real client IP | [#5](https://github.com/fosrl/badger/pull/5) ⚡ / [#9](https://github.com/fosrl/badger/pull/9) ⚡ / `onno204` + `hhftechnology` forks | Trusted-hop CF → X-Real-IP → X-Forwarded-For; `firstValidIP`; unit tests |

### Own work (no clean ticket)

| Area | What |
|---|---|
| Server TLS | PEM upload redesign (not EE table) |
| Server WG | Tunnel profiles without fake `sites.type` |
| Deploy | Ansible LE/CF Origin, troubleshooting |

### Review deferred (closed)

| Item | Resolution |
|---|---|
| full-tunnel IPv6 leak | `::/0` + `0.0.0.0/0` in `applyRoutingModeToAllowedIps` |
| Header validation drift | Shared `server/lib/headers/headerSchema.ts` for API + blueprints |
| Cert path dual implementation | `pathsForDomainRoot` used by upload + TraefikConfigManager |
| Olm 500ms Sleep on reconnect | Interruptible `waitForHolePunchSettle` (ctx / tunnel stop) |

---

## Community features

| Area | Upstream # | Feature |
|---|---|---|
| Domains | [#3243](https://github.com/fosrl/pangolin/issues/3243) | BYOC PEM path |
| Resources | [#3172](https://github.com/fosrl/pangolin/pull/3172) | Response headers |
| DX | [#3368](https://github.com/fosrl/pangolin/pull/3368) | npm test runner |
| Sites | own | Tunnel profiles + general-page edit |

---

## Graveyard status

**Server:** 11 bug ports + 4 features (see above). Branch mine of fosrl/pangolin documented earlier; value was open PR diffs.

**Newt:** 4 open PR ports + 1 closed-unmerged + 1 intent default. Skipped #324/#341 (stale/conflict), #355/#420/#403 (needs design).

**Gerbil:** #106 + #105 ported. Skipped #95 (TTL cache already re-notifies ≤2.5s), large perf #75/#64/#65, websocket-relay #77, dep-only bumps.

**Olm:** #123 closed-unmerged ported. Skipped #124 (API 426 — DX nice-to-have), #115 systemd-resolved (needs platform design), large websocket-relay #112, dep bumps.

**Badger:** closed #5/#9 + fork XFF logic ported + tests. Skipped open #24 large refactor, rebrand forks.

### FORK GRAVEYARD (2026-07-31 app-plus pass)

```
FORK GRAVEYARD:
  Network forks inventoried (paginated):
    fosrl/pangolin 752  (API forks_count=742)
    fosrl/newt       82
    fosrl/gerbil     30
    fosrl/olm        22
    fosrl/badger     22
  Compare method: gh compare main...owner:branch (owner:branch, not owner/repo)

  Pangolin:
    Starred + recent + known samples compared: ~40
    Ahead of upstream (content candidates): 0
    Identical/behind: all sampled (e.g. Arison99 behind 6813, 88plug behind 4478,
      Adityakk9031/zkulle identical). No unique plus code on network forks.

  Newt:
    Full owner inventory compared
    Small-tier ahead (1–4 commits): md-aamir-khan, playX18 (flake.nix hash only),
      myInstagramAlternative (stale go.mod bumps) → SKIP-noise
    Large ahead + behind≈759: diverged-old-base mirrors (mattv8 etc. recent commits
      are upstream merge PRs) → large-tier named, not wholesale-merged
    Ported from forks: 0 unique (value was already in open upstream PRs)

  Gerbil:
    Full inventory compared
    Ahead candidates: hhftechnology ahead_by=1 (tailscale rewrite, removes relay/)
      → SKIP-rebrand / alternate product
    Ported from forks: 0 (companion open PRs instead)

  Olm:
    Full inventory compared
    Ahead candidates: several large diverged (Lokowitz 277, water-sucks 255, …)
      → large-tier deferred; no small thesis-aligned slice
    Ported from forks: 0

  Badger:
    Full inventory compared
    Small-tier:
      onno204 (XFF) + hhftechnology (XFF+tests) → logic already ported from closed PRs;
        tests adapted into main_test.go (fork provenance)
      AstralDestiny → module rename noise SKIP
      marcschaeferger-org → .deepsource.toml SKIP
      Dervish12 → netflare rebrand SKIP
    Ported into plus: XFF/real-IP behavior + tests (PR #5/#9 + fork corroboration)

  Forks whose own issues/PRs/branches mined: onno204/hhftechnology (via closed PR
    lineage); full per-fork issue trackers on 0-star mirrors not re-listed (no ahead code).
```

### ECOSYSTEM

```
ECOSYSTEM:
  Companions mined into monorepo: fosrl/newt, gerbil, olm, badger
  Separate plus products: none (newt-plus left as MOVED.md pointer only)
  Survivors ported this pass: gerbil#106/#105, olm#123, badger#5/#9+forks
```

---

## DEPENDENCY AUDIT

```
UPSTREAM RELEASES (latest == in-tree):
  fosrl/pangolin 1.21.1  ·  fosrl/newt 1.15.0  ·  fosrl/gerbil 1.4.3
  fosrl/olm 1.8.1  ·  fosrl/badger v1.5.0
  (upstream HEAD matches release tags as of 2026-08-01)

DEPENDENCY AUDIT (server npm — always latest minor/patch + majors where viable):
  ✅ Patch/minor: next 16.2.12 · react/react-dom 19.2.8 · axios 1.19.0 · radix/aws/query …
  ✅ Majors applied:
     better-sqlite3 13.0.2 · ioredis 6.0.0 · js-yaml 5.2.2 (namespace imports)
     @asteasolutions/zod-to-openapi 9.1.0 · @dotenvx/dotenvx 2.19.1
     react-day-picker 10.0.1 (calendar ClassNames: table→month_grid)
     @types/node 26.1.2
  ⚠️  engines: node >=22 <26
  🔴 Major held: typescript 7 — typescript-eslint@8 peer is typescript <6.1.0
     (stay on typescript 6.0.3 until eslint stack supports TS 7)

DEPENDENCY AUDIT (Go components):
  ✅ go get -u=patch + tidy on newt/gerbil/olm; builds green
  ✅ gRPC 1.82.1, x/crypto/net/sys bumps, wireguard tip
  ⚠️  gvisor pinned to v0.0.0-20250503011706 (newer 20260801 breaks multi-package stack/)
```

---

## Build / verify

```bash
# Server (unchanged npm path)
npm ci && npm run set:oss && npm run set:sqlite
npx tsc --noEmit
npm test

# Go components (binaries under components/*/bin/)
make components-build
make components-test

# Local Docker images: pangolin-plus/{pangolin,gerbil,newt,olm}:local
make plus-images
# Optional push (refuses fosrl / ghcr.io/fosrl namespaces):
# make plus-images-push PLUS_REGISTRY=ghcr.io/88plug/pangolin-plus PLUS_TAG=local

# Compose edge stack (traefik:v3.7)
docker compose -f compose.plus.yaml up -d --build
# Lab newt (requires NEWT_ID + NEWT_SECRET; does not restart-loop without them):
# NEWT_ID=... NEWT_SECRET=... docker compose -f compose.plus.yaml --profile lab up -d
```

| Gate | Status |
|------|--------|
| Server `tsc` | PASS |
| Server `npm test` | 9/11 (openapi isolation pre-existing) |
| `make components-build` | newt + gerbil + olm binaries |
| `make components-test` | PASS |
| `make plus-images` | local Docker tags (optional if no Docker) |

---

## Contribute by porting

One matrix row → one upstream repo → minimal PR.

| Target upstream | Example first ports |
|-----------------|---------------------|
| fosrl/pangolin | #3445 sessions; #3335 OIDC; #3278 Remote-Groups |
| fosrl/newt | #424 registration; #413 reconnect; #412 races |
| fosrl/gerbil · olm · badger | After mining pass |

Always branch from **upstream tag/main**, not from a mixed monorepo dump, so reviewers see a clean component PR.

---

## Relationship to upstream

| Ref | Purpose |
|-----|---------|
| **[88plug/pangolin-plus](https://github.com/88plug/pangolin-plus) `main`** | **Product** — ship here |
| `origin` | 88plug/pangolin-plus |
| `upstream` | fosrl/pangolin (fetch/merge only) |
| fosrl/* tags | Upstream sources of truth for each component |
| See [UPSTREAM.md](UPSTREAM.md) | Sync + port-back workflow |

---

WireGuard® is a registered trademark of Jason A. Donenfeld. Pangolin branding belongs to Fossorial / upstream. This monorepo is an unofficial community plus distribution.
