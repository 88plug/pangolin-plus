# pangolin-plus

A community **plus fork** of the **Pangolin self-host stack** — not just the dashboard server.
One monorepo product that **mines** [fosrl/pangolin](https://github.com/fosrl/pangolin), [newt](https://github.com/fosrl/newt), [gerbil](https://github.com/fosrl/gerbil), [olm](https://github.com/fosrl/olm), and [badger](https://github.com/fosrl/badger) (and useful fork PRs), then ships **one** distribution.

> **The bar for every change:** one a thoughtful upstream maintainer would accept — small, focused, tested, verified before it ships. Branch **`claude/pangolin-plus`**. Nothing here is a throwaway hack. We do **not** publish separate `newt-plus` / `olm-plus` products.

**Layout**

| Path | Role | Base | Plus status |
|------|------|------|-------------|
| *(repo root)* | Pangolin CE server | **1.21.1** | **Mined** |
| [`components/newt/`](components/newt/) | Site connector | **1.15.0** | **Mined** |
| [`components/gerbil/`](components/gerbil/) | WireGuard interface mgr | **1.4.3** | Vendored (mine next) |
| [`components/olm/`](components/olm/) | Client | **1.8.1** | Vendored (mine next) |
| [`components/badger/`](components/badger/) | Traefik auth middleware | **v1.5.0** | Vendored (mine next) |
| [`deploy/`](deploy/) | Ansible + ops notes | — | Own work |
| [`compose.plus.yaml`](compose.plus.yaml) | Build full stack from this tree | — | Own work |

---

## Why a plus fork?

Upstream Pangolin is a **multi-binary edge** (server + newt + gerbil + olm + badger). Plusing only the server leaves site connectivity and clients broken in the real world. This fork is the **single** place those graveyards get mined into one coherent CE self-host distribution.

So pangolin-plus is:
1. **A daily-driver self-host stack** — controller, connector, WG helper, client sources, Badger, deploy glue.
2. **A proving ground for upstream** — each component delta is a port candidate back to the matching fosrl repo.

---

## How we\'re different — at a glance

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

### Gerbil / Olm / Badger

Vendored at current release tags for **one clone / one compose build**. Mining pass next (same app-plus procedure into these directories — not separate repos).

---

## Headline additions

**Server**
- PEM certificate upload (OSS BYOC) · tunnel profiles · OIDC open-redirect guard · custom response headers · audit/session/geoblock/API graveyard ports · `deploy/` Ansible · `npm test`

**Newt (in-tree)**
- Registration chain · reconnect WgData · healthcheck races · TLS ConnectionState · prefer-local-routes default true

**Distribution**
- `compose.plus.yaml` builds pangolin + gerbil (and optional newt) from this monorepo
- `make newt-test` / `make newt-build` from root

---

## Feature matrix

✓ = present · ◑ = partial · – = absent

| Capability | upstream CE stack | pangolin-plus monorepo |
|---|:--:|:--:|
| Pangolin CE server 1.21.x | ✓ | ✓ + plus deltas |
| Newt connector 1.15.x | ✓ (separate repo) | ✓ **in-tree + mined** |
| Gerbil / Olm / Badger sources | separate | ✓ **vendored** |
| PEM BYOC upload (OSS) | – | ✓ |
| WG tunnel profiles | – | ✓ |
| Newt reconnect/health correctness pack | open PRs | ✓ mined |
| Prefer local LAN over tunnel routes | flag off | ✓ default on |
| Single compose build of plus images | – | ✓ `compose.plus.yaml` |

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

### Own work (no clean ticket)

| Area | What |
|---|---|
| Server TLS | PEM upload redesign (not EE table) |
| Server WG | Tunnel profiles without fake `sites.type` |
| Deploy | Ansible LE/CF Origin, troubleshooting |

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

**Gerbil / Olm / Badger:** Not mined yet — trees vendored for the monorepo so the next pass is *into these directories*, not new repos.

**Public forks of fosrl/pangolin:** No competing ahead-of-main maintained plus found (742 forks mostly mirrors). 88plug/pangolin remote is dead (thousands behind).

---

## DEPENDENCY AUDIT

```
DEPENDENCY AUDIT (server):
  ✅ Auto-applied: (none — 1.21.1 lockfile baseline)
  ⚠️  Flagged: ncu patch bumps (peer conflicts if applied wholesale)
  🔴 Major: not auto-applied

DEPENDENCY AUDIT (newt):
  ✅ Baseline 1.15.0 green (make test)
  ⚠️  Open #428 go-deps group / #426 grpc — not auto-applied
```

---

## Build / verify

```bash
# Server
npm ci && npm run set:oss && npm run set:sqlite
npx tsc --noEmit
npm test

# Newt (in monorepo)
make newt-test
make newt-build

# Full stack images
docker compose -f compose.plus.yaml build
```

| Gate | Status |
|------|--------|
| Server `tsc` | PASS |
| Server `npm test` | 9/11 (openapi isolation pre-existing) |
| Newt `make test` | PASS |
| Newt `make local` | PASS |

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
| fosrl/* tags | Upstream sources of truth |
| `claude/pangolin-plus` | **Only** product branch — server + components + deploy |
| Standalone `~/newt-plus` | Mining workspace only → see `MOVED.md`; do not treat as product |

---

WireGuard® is a registered trademark of Jason A. Donenfeld. Pangolin branding belongs to Fossorial / upstream. This monorepo is an unofficial community plus distribution.
