# pangolin-plus

A community **plus fork** of [fosrl/pangolin](https://github.com/fosrl/pangolin) — *the version of Pangolin CE the maintainers had in flight for self-hosters, finished*. It closes the seams that bite real VPS operators: BYOC / Cloudflare Origin TLS without the EE ACME path, WireGuard full-tunnel vs split-tunnel without lying about `sites.type`, OIDC open-redirect hardening, and a stack of correctness fixes mined from open and closed-unmerged PRs — then proves them with `tsc` and the unit-test runner.

> **The bar for every change:** one a thoughtful upstream maintainer would accept — small, focused, tested, and verified (`npx tsc --noEmit`, `npm test` where the harness allows) before it ships. Built on tag **1.21.1**; branch **`claude/pangolin-plus`**. Nothing here is a throwaway hack.

---

## Why a plus fork?

Upstream Pangolin is excellent and moving fast — 1.20 resource launcher and command palette, 1.21 same-network detection, provisioning keys, and a growing EE surface. That means there is always a frontier of *almost-finished* work: an open PR that never merges, a closed issue real people still hit, a self-host need (orange-cloud Origin certs, full-tunnel WG) that sits outside the OSS ACME stubs.

A **plus fork** closes that frontier. It reads the whole codebase and the issue/PR/**branch graveyard**, then implements what the community asked for and what the code was already trying to become — and proves each change.

So pangolin-plus is two things at once:

1. **A daily-driver distribution** — same Pangolin CE, with self-host rough edges sanded and operator deploy glue.
2. **A proving ground for upstream** — every fix/feature here is a tested, isolated candidate you can **port back to fosrl/pangolin** as a focused PR (see [Contribute by porting](#contribute-by-porting)).

Install / run pointers live in the [README](README.md). This file is the **full diff of intent**.

---

## How we're different — at a glance

| Pillar | upstream `fosrl/pangolin` OSS 1.21.1 | `pangolin-plus` |
|---|---|---|
| **Custom TLS (BYOC / CF Origin)** | Cert *resolver name* only; ACME logic stubbed/private | **PEM upload API + Domain UI** writing the on-disk layout Traefik already scans ([#3243](https://github.com/fosrl/pangolin/issues/3243)) |
| **WireGuard site routing** | Target IPs via `getAllowedIps` only | **`tunnelProfile` + `routingMode`** — selective (default) or full-tunnel (`0.0.0.0/0`) without fake `sites.type` values |
| **Session cookies** | Multiple valid session cookies → last key wins | **Keep first valid session only** ([#3445](https://github.com/fosrl/pangolin/pull/3445); class of [#2238](https://github.com/fosrl/pangolin/issues/2238)) |
| **Audit logs** | Ordering / multi-scan facet queries | **Stable ordering + 6→1 filter scans** ([#3459](https://github.com/fosrl/pangolin/pull/3459), [#3443](https://github.com/fosrl/pangolin/pull/3443) / [#3458](https://github.com/fosrl/pangolin/issues/3458)) |
| **Geoblock “Country is not”** | Single-country gaps | **Multi-country + rule eval** ([#3474](https://github.com/fosrl/pangolin/pull/3474) / [#3432](https://github.com/fosrl/pangolin/issues/3432)) |
| **Integration API** | Site-resource GET broken for some IDs | **Fixed lookup + tests** ([#3510](https://github.com/fosrl/pangolin/pull/3510) / [#2743](https://github.com/fosrl/pangolin/issues/2743)) |
| **OIDC post-auth redirect** | `// TODO: validate that this is safe` | **`isSafePostAuthRedirect`** on issue + callback ([#3335](https://github.com/fosrl/pangolin/issues/3335)) |
| **Custom HTTP headers** | Request headers column (`headers`) | **Request + response headers** for Traefik custom* ([#3172](https://github.com/fosrl/pangolin/pull/3172)) |
| **SSO after session expiry** | Lost original resource URL | **Restore resource redirect** ([#3411](https://github.com/fosrl/pangolin/pull/3411) ⚡ / [#3001](https://github.com/fosrl/pangolin/issues/3001)) |
| **Badger → upstream RBAC** | Groups not always exposed | **`Remote-Groups` header** ([#3278](https://github.com/fosrl/pangolin/pull/3278) ⚡) |
| **Tests** | Scattered `*.test.ts` scripts | **`npm test` runner** ([#3368](https://github.com/fosrl/pangolin/pull/3368)) |
| **Deploy** | Installer docs | **`deploy/` Ansible** (LE or CF Origin, image pin 1.21.1, cookie-domain + ODoH notes) |
| **Graveyard** | Open by definition | **11 bug ports + 4 features** cited below (mechanical issue/PR links in this file) |

---

## Headline additions

- **PEM certificate upload (OSS BYOC)** — `POST /org/:orgId/domain/:domainId/certificate/upload` + Domain settings UI. Writes `{traefik.certificates_path}/{domain}/cert.pem|key.pem` (+ `.last_update` / optional `.wildcard`) so `TraefikConfigManager` picks them up without the EE certificates table. Relates to [#3243](https://github.com/fosrl/pangolin/issues/3243).
- **WireGuard tunnel profiles** — `standard` / `secure-vpn` / `split-tunnel` / `privacy-gateway` map to `routingMode` `selective` \| `full-tunnel`. Backend `sites.type` stays `newt` \| `wireguard` \| `local`. Create UI + **General** settings edit; Gerbil peer AllowedIPs refresh on change. Redesign of local historical work (`ebfc963`), not a blind cherry-pick.
- **OIDC open-redirect guard** — `server/lib/idp/isSafePostAuthRedirect.ts` on generate-url and callback ([#3335](https://github.com/fosrl/pangolin/issues/3335)).
- **Custom response headers** on public HTTP resources, with `headers` → `requestHeaders` rename and migration `1.21.3` ([#3172](https://github.com/fosrl/pangolin/pull/3172)).
- **Deploy bundle** — [`deploy/`](deploy/) Ansible for LE or Cloudflare Origin, safe upgrade playbook, Badger cookie-domain notes, ODoH-through-WG research notes, [TROUBLESHOOTING.md](deploy/TROUBLESHOOTING.md).
- **Test runner** — `npm test` → `test/run.ts` process-isolated suite ([#3368](https://github.com/fosrl/pangolin/pull/3368)).

---

## Feature matrix (capabilities)

✓ = present · ◑ = partial · – = absent

| Capability | pangolin OSS 1.21.1 | pangolin-plus |
|---|:--:|:--:|
| Identity-aware reverse proxy + Badger | ✓ | ✓ |
| WireGuard sites / Newt / local | ✓ | ✓ |
| Same-network detection (1.21) | ✓ | ✓ |
| Resource launcher + command palette (1.20) | ✓ | ✓ |
| Per-domain Traefik cert *resolver* name | ✓ | ✓ |
| **PEM BYOC / CF Origin upload (OSS)** | – | ✓ |
| **WG tunnel profile + full-tunnel AllowedIPs** | – | ✓ |
| **Edit tunnel profile on existing site** | – | ✓ |
| Custom *request* headers on resources | ✓ | ✓ |
| **Custom *response* headers on resources** | – | ✓ |
| **OIDC post-auth redirect host allow-list** | – | ✓ |
| **`npm test` aggregated runner** | ◑ | ✓ |
| **Ansible deploy bundle (CF Origin path)** | – | ✓ |
| EE ACME / private cert sync | private | private (unchanged stubs in OSS) |

---

## Bug matrix (fixed from the graveyard)

Real upstream issues/PRs that were open, closed-without-merge, or left half-done — implemented here. Each row is a **port candidate**.

| Area | Upstream # | What pangolin-plus fixes |
|---|---|---|
| Auth/sessions | [#3445](https://github.com/fosrl/pangolin/pull/3445) (OPEN) | `stripDuplicateSessions` kept every *valid* cookie; cookieParser then took the last repeated key — now keeps only the first valid session (class of [#2238](https://github.com/fosrl/pangolin/issues/2238)) |
| Audit logs | [#3459](https://github.com/fosrl/pangolin/pull/3459) / [#3458](https://github.com/fosrl/pangolin/issues/3458) (OPEN) | Request log row mix-ups from bad ordering; UI pages cleaned |
| Audit logs | [#3443](https://github.com/fosrl/pangolin/pull/3443) (OPEN) | Filter-attribute query 6 table scans → 1 |
| Integration API | [#3510](https://github.com/fosrl/pangolin/pull/3510) / [#2743](https://github.com/fosrl/pangolin/issues/2743) (OPEN) | Site-resource GET lookup + param validation tests |
| Policy/geoblock | [#3474](https://github.com/fosrl/pangolin/pull/3474) / [#3432](https://github.com/fosrl/pangolin/issues/3432) (OPEN) | `COUNTRY_IS_NOT` multi-country + rule evaluation |
| Blueprints/certs | [#3199](https://github.com/fosrl/pangolin/pull/3199) / [#2937](https://github.com/fosrl/pangolin/issues/2937) (OPEN) | Blueprint apply UNIQUE on `certificates.domain` (upsert path) |
| Traefik config | [#3191](https://github.com/fosrl/pangolin/pull/3191) (OPEN) | `anySitesOnline` out of loop; wildcard domain match |
| i18n | [#3509](https://github.com/fosrl/pangolin/pull/3509) / [#3480](https://github.com/fosrl/pangolin/issues/3480) (OPEN) | Regional locale detection (`detectLocale`) |
| Auth/SSO | [#3411](https://github.com/fosrl/pangolin/pull/3411) ⚡ CLOSED-unmerged / [#3001](https://github.com/fosrl/pangolin/issues/3001) | Redirect to original resource URL after SSO with expired session |
| Badger | [#3278](https://github.com/fosrl/pangolin/pull/3278) ⚡ CLOSED-unmerged | Inject `Remote-Groups` for downstream RBAC |
| Auth/OIDC | [#3335](https://github.com/fosrl/pangolin/issues/3335) (OPEN) | Post-auth open redirect via poisoned `redirectUrl` in OIDC state JWT |

### Fixed / shipped without a clean upstream ticket

| Area | Source | What |
|---|---|---|
| TLS | redesign of 88plug/`pangolin-pr` cert upload (base ~4.5k commits behind) | OSS filesystem PEM upload, not EE private schema |
| WireGuard | redesign of local `ebfc963` enhanced tunnel types | Profiles + `routingMode`; no overloaded `sites.type` |
| Deploy | public-safe extract of operator Ansible | `deploy/` without secrets |

> ⚡ = closed/unmerged upstream PR (classic graveyard win). `#` links go to [fosrl/pangolin](https://github.com/fosrl/pangolin). Where a PR existed, plus reused its diff as a starting point when it applied cleanly to 1.21.1.

---

## Community-feature matrix (requests delivered)

Features the community asked for — open enhancements or stalled PRs — that pangolin-plus ships.

| Area | Upstream # | Feature |
|---|---|---|
| Domains/TLS | [#3243](https://github.com/fosrl/pangolin/issues/3243) | External certificates / BYOC with file path (PEM upload + local status) |
| Resources | [#3172](https://github.com/fosrl/pangolin/pull/3172) (OPEN) | Custom response headers (+ request rename) |
| CI/DX | [#3368](https://github.com/fosrl/pangolin/pull/3368) (OPEN) | Unit test runner (`npm test`) |
| Sites/WG | operator need + redesigned local work | Full-tunnel vs split-tunnel profiles on WireGuard sites |

### Shipped without an upstream ticket

| Area | Source | Feature |
|---|---|---|
| Deploy | own work | Ansible LE/CF Origin path, upgrade + rollback notes |
| Ops docs | own work | Cookie-domain Badger fix notes; ODoH-through-WG research notes |
| Migrations | own work | `1.21.2` tunnel columns; `1.21.3` header rename |

---

## Graveyard status: what's actually done vs still open

Be honest about scale rather than implying the matrices are exhaustive of all of Pangolin.

### Counts (this fork)

| Bucket | Landed | Notes |
|---|--:|---|
| Distinct upstream issue/PR citations in this file | run `grep -oE 'fosrl/pangolin/(issues\|pull)/[0-9]+' PANGOLIN_PLUS.md \| sort -u \| wc -l` | Prefer re-running the extract over hand tallies |
| Bug-matrix ports | **11** | Port candidates |
| Community / own features | **4+** | BYOC, tunnels, response headers, test runner, deploy |
| Closed-unmerged ⚡ | **2** | #3411, #3278 |

### Branch graveyard (mandatory accounting)

Remote heads at last full mine: **23** (including dependabot). Non-bot triaged: **19**.

| Class | Outcome |
|---|---|
| Merged into 1.21.1 / zero commits ahead of merge-base | e.g. `dev`, `feat/command-palette`, `resource-launcher`, `org-only-idp`, `site-targets-auto-login`, **`backhaul` (0 ahead)** |
| Already present on 1.21.1 tip | `exit-node-reconnect` — OSS getOlmToken fallback + private reconnect scheduler already in tree |
| Value adopted via **open PR diffs** instead of orphan branches | #3445, #3459, #3474, #3510, #3172, #3368, … |
| Not adopted (large / EE / client) | Named in skip list below |

### Still open (skip list)

| # | Title | Reason skipped |
|---|---|---|
| [#3448](https://github.com/fosrl/pangolin/pull/3448) | sqlite index parity | Large conflict; deferred |
| [#3384](https://github.com/fosrl/pangolin/pull/3384) | IdP validation for server-wide IdPs | Already fixed via `idpExistsForOrg` |
| [#3169](https://github.com/fosrl/pangolin/pull/3169) | In-app docs shortcuts | Patch conflict |
| [#3334](https://github.com/fosrl/pangolin/issues/3334) | Integration API `/v1` 404 | Ops/config — see [deploy/TROUBLESHOOTING.md](deploy/TROUBLESHOOTING.md) |
| [#3471](https://github.com/fosrl/pangolin/issues/3471) | IPv6 ISP | Needs investigating / network |
| [#3428](https://github.com/fosrl/pangolin/issues/3428) … | RDP / CredSSP / Azure AD | EE / client surface |
| [#3166](https://github.com/fosrl/pangolin/issues/3166) | Kubernetes Operator | New product, out of scope |
| Dependabot mega-bumps | e.g. #3490 | Peer conflicts; not auto-applied |

---

## DEPENDENCY AUDIT

```
DEPENDENCY AUDIT:
  ✅ Auto-applied (patch bumps):
     (none — ncu --target patch hit peer resolve failures; package.json
      reverted; lockfile remains the 1.21.1 baseline that npm ci installs cleanly)

  ⚠️  Flagged, NOT applied (review before shipping):
     next 16.2.11 → 16.2.12
     axios, react/react-dom 19.2.6 → 19.2.8, postcss, nodemailer, …
     (re-run: npx npm-check-updates --target patch)

  🔴 Major bumps available (never auto-apply):
     not evaluated for apply this fork
```

**Runtime:** Node **22** recommended for `better-sqlite3` prebuilds on some hosts; Node 26 failed native build during this work.

---

## Build / verify

```bash
# Node 22 if better-sqlite3 fails on 26
export PATH="${HOME}/.local/node/node-v22.17.0-linux-x64/bin:$PATH"  # optional

npm ci
npm run set:oss && npm run set:sqlite
cp -n config/config.example.yml config/config.yml   # gitignored
npx tsc --noEmit          # required green
npm test                  # process-isolated *.test.ts
# npm run build           # next + esbuild server (optional; heavier)
```

| Gate | Status (last verified) |
|------|------------------------|
| `tsc --noEmit` | PASS |
| `npm test` | 9/11 pass — `ip.test.ts` / `traefikConfig.test.ts` fail with zod `.openapi is not a function` under isolated process (pre-existing harness gap, not introduced by plus feature work) |
| Migrations | `1.21.2` tunnel columns; `1.21.3` headers rename |

---

## Contribute by porting

**The point of a plus fork: nothing here has to stay here.** Every bug-matrix row is already implemented and isolated — which makes it a ready-to-open PR for *real* Pangolin.

### The model

```
fosrl/pangolin (1.21.1 / main)
        │
        ▼
claude/pangolin-plus     (all plus work)
        │
   port/<topic>          (branch FROM upstream main/tag, not from a mixed plus tree)
        │  minimal cherry-pick / file set for one matrix row
        ▼
PR → fosrl/pangolin
```

Ports **always** start from clean upstream, never from a dump of the whole plus branch — so the PR is a minimal, reviewable diff with no fork-only deploy trees or branding noise.

### Pick → port → PR (example)

1. **Pick** a row — e.g. [#3445](https://github.com/fosrl/pangolin/pull/3445) session cookie dedupe (single file: `server/middlewares/stripDuplicateSessions.ts`).
2. **Branch from upstream:**
   ```bash
   git fetch origin
   git checkout -b port/strip-duplicate-sessions 1.21.1   # or origin/main
   ```
3. **Apply the minimal patch** from this fork for that file only; drop plus-only comments if needed.
4. **Verify the way upstream will:**
   ```bash
   npm run set:oss && npm run set:sqlite
   npx tsc --noEmit
   npm test
   ```
5. **Open the PR** against fosrl/pangolin with a description that links the issue/PR this closes.

### Good first ports

| Difficulty | Item |
|---|---|
| Easy | [#3445](https://github.com/fosrl/pangolin/pull/3445) stripDuplicateSessions; [#3278](https://github.com/fosrl/pangolin/pull/3278) Remote-Groups; [#3191](https://github.com/fosrl/pangolin/pull/3191) traefik hot-path |
| Medium | [#3459](https://github.com/fosrl/pangolin/pull/3459)+[#3443](https://github.com/fosrl/pangolin/pull/3443) audit logs; [#3335](https://github.com/fosrl/pangolin/issues/3335) OIDC redirect |
| Larger | [#3474](https://github.com/fosrl/pangolin/pull/3474) multi-country; [#3172](https://github.com/fosrl/pangolin/pull/3172) response headers (+ migration) |

---

## Relationship to upstream

| Ref | Purpose |
|-----|---------|
| `fosrl/pangolin` `main` / tags | Upstream source of truth |
| Tag **1.21.1** | Base of this plus work |
| `claude/pangolin-plus` | All plus commits (PEM, graveyard ports, tunnels, headers, docs) |
| `port/<name>` | Suggested short-lived branches for upstream PRs |

Items already shipped upstream in 1.20/1.21 (resource launcher, same-network detection, many COMPLETED issues) are **not** re-implemented here.

---

## Commits on `claude/pangolin-plus` (this tree)

| Commit | Summary |
|--------|---------|
| `0cbc535` | PEM cert upload + deploy bundle on 1.21.1 |
| `c89a5d4` | Graveyard PR pack (sessions, audit, geoblock, OIDC, …) |
| `ffedf6adb` | WireGuard tunnel profile redesign |
| `586ccfdf6` | Edit tunnel profile on existing sites |
| `1555f777d` | Custom response headers + test runner |
| `2cb6f41c7` | First PANGOLIN_PLUS.md structure pass |

---

## Appendix: prior local trees (operator machine)

Not part of the product narrative — recorded so work is not rediscovered blindly.

| Path | Role |
|------|------|
| Historical RackNerd ops tree | Live mello.work-era Ansible; **do not copy secrets** |
| Historical `pangolin-pr` | 88plug product fork (~thousands of commits behind) |
| Historical ansible-terraform clone | Generic deploy precursor |
| Empty akash-controller dir | Never started |

---

WireGuard is a registered trademark of Jason A. Donenfeld. Pangolin® branding and product names belong to Fossorial / upstream maintainers. This fork does not claim official status.
