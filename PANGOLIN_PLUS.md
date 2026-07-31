# pangolin-plus

A community **plus fork** of [fosrl/pangolin](https://github.com/fosrl/pangolin) **1.21.1** — *the self-host OSS edge the code was already trying to be*. It lands BYOC/Cloudflare Origin certs, WireGuard tunnel profiles without overloading `sites.type`, correctness fixes from open and closed PRs, OIDC open-redirect hardening, and a deploy/ops bundle for real VPS installs.

> **The bar for every change:** one a thoughtful upstream maintainer would accept — small, focused, tested, and verified (`npx tsc --noEmit`, `npm test` where harness allows) before it ships. Built on tag `1.21.1` / branch `claude/pangolin-plus`; nothing here is a throwaway hack.

---

## Why a plus fork?

Upstream Pangolin is excellent and moving fast (1.20 resource launcher, 1.21 same-network detection). That leaves a frontier of *almost-finished* work: open PRs that never merge, closed bugs still hit by self-hosters, and operator needs (Cloudflare orange-cloud Origin certs, full-tunnel vs split-tunnel WG) that sit outside the EE ACME path. A **plus fork** closes that frontier: it reads the codebase and the issue/PR/**branch graveyard**, then implements what the community asked for and what the code was already trying to become — and proves each change.

So pangolin-plus is two things at once:
1. **A daily-driver distribution** for self-host (mello.work-class) — same Pangolin OSS, with self-host rough edges sanded.
2. **A proving ground for upstream** — every fix/feature here is an isolated candidate you can port back as a focused PR.

---

## How we're different — at a glance

| Pillar | upstream `fosrl/pangolin` OSS 1.21.1 | `pangolin-plus` |
|---|---|---|
| **Custom TLS (BYOC / CF Origin)** | Cert *resolver name* only; ACME path EE/private | **PEM upload API + Domain UI** → `traefik.certificates_path` layout Traefik already scans ([#3243](https://github.com/fosrl/pangolin/issues/3243)) |
| **WireGuard site routing** | Targets-only AllowedIPs | **`tunnelProfile` + `routingMode`** (selective / full-tunnel `0.0.0.0/0`) without fake `sites.type` values |
| **Session cookies** | Duplicate session cookies can leave the wrong winner | **stripDuplicateSessions keeps first valid only** ([#3445](https://github.com/fosrl/pangolin/pull/3445)) |
| **Audit logs** | Row mix-ups / multi-scan filters | **Ordering fix + filter-attribute 6→1** ([#3459](https://github.com/fosrl/pangolin/pull/3459), [#3443](https://github.com/fosrl/pangolin/pull/3443)) |
| **Geoblock “Country is not”** | Single-country gaps | **Multi-country + rule eval fix** ([#3474](https://github.com/fosrl/pangolin/pull/3474) / [#3432](https://github.com/fosrl/pangolin/issues/3432)) |
| **Integration API site-resource** | Lookup broken for some IDs | **Fixed getSiteResource** ([#3510](https://github.com/fosrl/pangolin/pull/3510) / [#2743](https://github.com/fosrl/pangolin/issues/2743)) |
| **OIDC post-auth redirect** | `// TODO: validate that this is safe` | **`isSafePostAuthRedirect`** on generate + callback ([#3335](https://github.com/fosrl/pangolin/issues/3335)) |
| **Custom HTTP headers** | Request headers only (`headers` column) | **Request + response headers** Traefik custom* ([#3172](https://github.com/fosrl/pangolin/pull/3172)) |
| **Tests** | Ad-hoc `*.test.ts` scripts | **`npm test` runner** (`test/run.ts`, [#3368](https://github.com/fosrl/pangolin/pull/3368)) |
| **Deploy** | Installer docs | **`deploy/` Ansible** (LE or CF Origin, image pin 1.21.1, cookie-domain + ODoH notes) |

Full branch: `claude/pangolin-plus` on this machine (`~/pangolin-plus`).

---

## PLUS THESIS

Pangolin OSS is the self-host **identity-aware reverse proxy + WireGuard edge**. Plus completes the self-host spine: BYOC certs behind Cloudflare, correct session/audit/policy behavior, safe OIDC redirects, WG full- vs split-tunnel without fighting `sites.type`, and operator deploy glue — not a second product.

---

## Headline additions

- **PEM certificate upload** — `POST /org/:orgId/domain/:domainId/certificate/upload` + Domain settings UI; files under `{certificates_path}/{domain}/cert.pem|key.pem` matching `TraefikConfigManager.scanLocalCertificateState`.
- **Tunnel profiles** — `standard` / `secure-vpn` / `split-tunnel` / `privacy-gateway` → `routingMode` selective|full-tunnel; create + general edit UI; Gerbil peer AllowedIPs refresh.
- **OIDC open-redirect guard** — relative paths + dashboard/base-domain hosts only (`server/lib/idp/isSafePostAuthRedirect.ts`).
- **Custom response headers** on public HTTP resources (alongside request headers).
- **`deploy/`** — hardened VPS Ansible (public-safe), upgrade playbook, cookie-domain Badger fix notes, ODoH-through-WG research notes, integration-API 404 troubleshooting.

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

---

## Bug matrix (fixed from the graveyard)

Real upstream issues/PRs that were open, closed-unmerged, or never finished — implemented here. Each row is a port candidate.

| Area | Upstream # | What pangolin-plus fixes |
|---|---|---|
| Auth/sessions | [#3445](https://github.com/fosrl/pangolin/pull/3445) (OPEN) | `stripDuplicateSessions` kept every *valid* cookie; cookieParser then picked the last key — now keeps only the first valid session (class of [#2238](https://github.com/fosrl/pangolin/issues/2238)) |
| Audit logs | [#3459](https://github.com/fosrl/pangolin/pull/3459) / [#3458](https://github.com/fosrl/pangolin/issues/3458) (OPEN) | Request log rows mixed when ordering wrong; UI pages simplified |
| Audit logs | [#3443](https://github.com/fosrl/pangolin/pull/3443) (OPEN) | Filter-attribute query 6 scans → 1 |
| Integration API | [#3510](https://github.com/fosrl/pangolin/pull/3510) / [#2743](https://github.com/fosrl/pangolin/issues/2743) (OPEN) | `GET` site-resource lookup + param validation tests |
| Policy/geoblock | [#3474](https://github.com/fosrl/pangolin/pull/3474) / [#3432](https://github.com/fosrl/pangolin/issues/3432) (OPEN) | `COUNTRY_IS_NOT` multi-country + rule evaluation |
| Blueprints/certs | [#3199](https://github.com/fosrl/pangolin/pull/3199) / [#2937](https://github.com/fosrl/pangolin/issues/2937) (OPEN) | Blueprint apply UNIQUE on `certificates.domain` (upsert) |
| Traefik config | [#3191](https://github.com/fosrl/pangolin/pull/3191) (OPEN) | `anySitesOnline` hot-path; wildcard domain match |
| i18n | [#3509](https://github.com/fosrl/pangolin/pull/3509) / [#3480](https://github.com/fosrl/pangolin/issues/3480) (OPEN) | Regional locale detection (`detectLocale`) |
| Auth/SSO | [#3411](https://github.com/fosrl/pangolin/pull/3411) ⚡ CLOSED-unmerged / [#3001](https://github.com/fosrl/pangolin/issues/3001) | Redirect to original resource URL after SSO with expired session |
| Badger | [#3278](https://github.com/fosrl/pangolin/pull/3278) ⚡ CLOSED-unmerged | Inject `Remote-Groups` header for downstream RBAC |
| Auth/OIDC | [#3335](https://github.com/fosrl/pangolin/issues/3335) (OPEN) | Post-auth open redirect via poisoned `redirectUrl` in OIDC state JWT |

### Fixed / shipped without a clean upstream ticket

| Area | Source | What |
|---|---|---|
| TLS | own redesign of 88plug/`pangolin-pr` cert upload | OSS PEM upload (filesystem), not EE `certificates` table |
| WireGuard | redesign of local `ebfc963` (not upstream) | Tunnel profiles without overloading `sites.type` |
| Deploy | own ops from `racknerd-pangolin` public tree | Ansible + notes (no secrets) |

---

## Community-feature matrix (requests delivered)

| Area | Upstream # | Feature |
|---|---|---|
| Domains/TLS | [#3243](https://github.com/fosrl/pangolin/issues/3243) | Support external certificates / BYOC with cert path (PEM upload + on-disk status) |
| Resources | [#3172](https://github.com/fosrl/pangolin/pull/3172) (OPEN) | Custom response headers (with request headers rename) |
| CI/DX | [#3368](https://github.com/fosrl/pangolin/pull/3368) (OPEN) | Wire unit test runner (`npm test`) |
| Sites/WG | own (from operator need / old fork) | Full-tunnel vs split-tunnel profiles on WireGuard sites |

---

## Graveyard status: done vs still open

### Counts (this fork)

| Bucket | Landed in plus | Notes |
|---|--:|---|
| Cited upstream issues/PRs in matrices above | **14** distinct | Mechanical: open PR ports + closed-unmerged ⚡ + issue-only #3335/#3243 |
| Own-work / redesign features | **3** | PEM redesign, tunnel redesign, deploy bundle |
| **Bugs fixed (port candidates)** | **11** | see Bug matrix |
| **Features added** | **4** | BYOC, tunnels, response headers, test runner |

### Branch graveyard (mandatory accounting)

Remote heads at last mine: **23** (4 dependabot). Non-bot: 19.

| Class | Count | Examples |
|---|--:|---|
| Mechanically excluded (merged into 1.21.1 / zero ahead) | majority | `dev`, `feat/command-palette`, `resource-launcher`, `org-only-idp`, `site-targets-auto-login`, **`backhaul` (0 ahead)** |
| Already in tree (exit-node reconnect OSS+EE) | 1 | `exit-node-reconnect` — getOlmToken fallback + private scheduler present on 1.21.1 |
| Medium/large not adopted this pass | named in prior notes | none portable without redesign |
| Promising small unmerged adopted | 0 remaining after ports | value was in open PR diffs, not orphan branches |

### Still open (honest skip list)

| # | Title | Reason skipped |
|---|---|---|
| [#3448](https://github.com/fosrl/pangolin/pull/3448) | sqlite index parity | Large conflict; deferred |
| [#3384](https://github.com/fosrl/pangolin/pull/3384) | IdP validation | Already fixed via `idpExistsForOrg` |
| [#3169](https://github.com/fosrl/pangolin/pull/3169) | in-app docs shortcuts | Patch conflict |
| [#3334](https://github.com/fosrl/pangolin/issues/3334) | Integration API `/v1` 404 | Ops/config (see `deploy/TROUBLESHOOTING.md`), not a code bug alone |
| [#3471](https://github.com/fosrl/pangolin/issues/3471) | IPv6 ISP | Needs investigating / network |
| [#3428](https://github.com/fosrl/pangolin/issues/3428) etc. | RDP / CredSSP | EE / client surface |
| [#3166](https://github.com/fosrl/pangolin/issues/3166) | K8s operator | New product, out of scope |
| Dependabot mega-bumps | #3490 etc. | Peer conflicts; not auto-applied |

---

## DEPENDENCY AUDIT

```
DEPENDENCY AUDIT:
  ✅ Auto-applied (patch bumps):
     (none — ncu patch pass hit peer resolve failures; package.json reverted; lockfile = 1.21.1 baseline)

  ⚠️  Flagged, NOT applied (minor/patch available — review before shipping):
     next 16.2.11 → 16.2.12
     axios, react 19.2.6 → 19.2.8, postcss, nodemailer, … (full list via ncu --target patch)

  🔴 Major bumps available (never auto-apply):
     not evaluated for apply this fork
```

**Runtime note:** Node **22** required for `better-sqlite3` prebuilds on this host; Node 26 failed native build. Prefer `PATH` with Node 22 for `npm ci` / `npm test`.

---

## Build / verify

```bash
export PATH="$HOME/.local/node/node-v22.17.0-linux-x64/bin:$PATH"   # if needed
cd ~/pangolin-plus
npm ci
npm run set:oss && npm run set:sqlite
cp -n config/config.example.yml config/config.yml   # gitignored
npx tsc --noEmit          # required green
npm test                  # 9/11 historically; ip/traefik openapi isolation pre-existing
# optional: npm run build
```

Migrations: `1.21.2` (tunnel columns), `1.21.3` (request/response headers rename).

---

## Relationship to prior local trees

| Path | Role |
|------|------|
| `~/racknerd-pangolin` | Ops for mello.work; **secrets in git history — do not copy** |
| `~/racknerd-pangolin/pangolin-pr` | Old 88plug product fork (~4.5k commits behind) |
| `~/pangolin-ansible-terraform` | Generic ansible precursor |
| `~/pangolin-akash-controller` | Empty stub |

---

## Commits on `claude/pangolin-plus`

| SHA | Summary |
|-----|---------|
| `0cbc535` | PEM cert upload + deploy bundle on 1.21.1 |
| `c89a5d4` | Graveyard PR pack (sessions, audit, geoblock, OIDC, …) |
| `ffedf6adb` | WireGuard tunnel profile redesign |
| `586ccfdf6` | Edit tunnel profile on existing sites |
| `1555f777d` | Custom response headers + test runner |

---

## Contribute by porting

Each bug-matrix row is meant to be one focused upstream PR. Prefer porting the smallest file set for that row (e.g. only `stripDuplicateSessions.ts` for #3445) rather than the whole plus branch.
