# pangolin-plus

**Base:** [fosrl/pangolin](https://github.com/fosrl/pangolin) **1.21.1** (2026-07-30)  
**Branch:** `claude/pangolin-plus`  
**As of:** 2026-07-31

Consolidates the best of prior local Pangolin work onto current upstream.

## Why a plus fork

Your previous trees were built on late-2025 Pangolin. Upstream has moved **~4,500 commits** since the `88plug/pangolin` fork tip (Dec 2025). Direct cherry-pick of old patches fails. This repo starts from **1.21.1** and re-ports what still matters.

## Upstream changed a lot (1.19 → 1.21)

| Version | Highlights (from release notes) |
|---------|----------------------------------|
| **1.21** | Same-network detection (no relay when client+site share LAN); access-token session persistence; IdP last-used; private-resource enable toggle; pending site/resource provisioning; integration API cleanup |
| **1.20** | Resource launcher; global command palette; geoblock “Country Is Not”; VNC username for macOS |
| Earlier | Custom Traefik **certResolver** per domain, prefer-wildcard, launcher, labels, blueprints, provisioning keys… |

OSS `DomainCertForm` already supports **cert resolver name** (default / custom Traefik resolver). It does **not** ship PEM upload for Cloudflare Origin Certs — that remains a plus delta.

## What we brought in

### 1. Custom PEM certificate upload (from `racknerd-pangolin/pangolin-pr`)

Re-implemented against 1.21.1 (filesystem layout Traefik already scans):

| Piece | Path |
|-------|------|
| Upload API | `server/routers/certificates/uploadCertificate.ts` |
| Local status API | `server/routers/certificates/getLocalCertificate.ts` |
| Routes | `POST …/certificate/upload`, `GET …/certificate/local` in `server/routers/external.ts` |
| Action | `ActionsEnum.uploadCertificate` (auto-granted to admin roles via `ensureActions`) |
| UI | `src/components/DomainCertForm.tsx` — PEM paste + overwrite confirm + on-disk status |
| i18n | `messages/en-US.json` keys |

**Layout written** (matches `TraefikConfigManager.scanLocalCertificateState`):

```
{traefik.certificates_path}/{baseDomain}/cert.pem
{traefik.certificates_path}/{baseDomain}/key.pem
{traefik.certificates_path}/{baseDomain}/.last_update
{traefik.certificates_path}/{baseDomain}/.wildcard   # optional
```

Also merges into `traefik.dynamic_cert_config_path` when configured.

**Not ported from old fork:** writing PEMs into the private EE `certificates` table. EE already has its own ACME/cert path; OSS-plus stays on-disk so it works without private schema.

### 2. Deploy / ops bundle (`deploy/`)

From `~/racknerd-pangolin` (public + docs) and `~/pangolin-ansible-terraform`:

| File | Source |
|------|--------|
| `deploy/pangolin.yml` | public Ansible deploy (LE or Cloudflare Origin), image **pinned 1.21.1** |
| `deploy/upgrade-pangolin.yml` | safe upgrade + rollback |
| `deploy/inventory.ini.example` | inventory template only |
| `deploy/playbook-simple.yml` | single-file idempotent deploy (Ubuntu) |
| `deploy/playbook-debian-trixie.yml` | Debian Trixie variant |
| `deploy/traefik-cookie-domain-fix.md` | Badger session cookie domain rewrite (proxy-cookie plugin) |
| `deploy/odoh-wireguard-dns-notes.md` | ODoH-through-WG tunnel DNS research (unfinished) |
| `deploy/README.md` | quick start |

**No secrets** in this tree (no real `cert.pem` / `key.pem` / inventory passwords).

### 3. Deferred (still valuable, not rebased)

| Item | Why deferred |
|------|----------------|
| Enhanced tunnel types + site regenerate/toggle WG (`ebfc963`, ~1351 LOC) | Touches site/gerbil/newt schema heavily; 1.21 already has same-network detection, site restart/approve/reject, provisioning keys. Needs a fresh design against current models, not a patch apply. |
| Docker cache-bust commits | Noise; use normal build args. |
| Empty `~/pangolin-akash-controller` idea | Never started; re-open as a separate SDL/controller project if needed. |

## Prior local trees (reference only)

| Path | Role |
|------|------|
| `~/racknerd-pangolin` | Live ops for mello.work (Dec 2025); dirty tree; **secrets in git history** |
| `~/racknerd-pangolin/pangolin-pr` | Old product fork on ~Dec 2025 base |
| `~/pangolin-ansible-terraform` | Generic ansible (upstream clone, local rewrite) |
| `~/pangolin-akash-controller` | Empty stub |

## Build / run

```bash
cd ~/pangolin-plus
# follow upstream docs for OSS build
npm ci
# BUILD=oss make / npm scripts per Makefile & README
```

Deploy path:

```bash
cd deploy
cp inventory.ini.example inventory.ini
# for cloudflare mode: place cert.pem + key.pem next to playbook
ansible-playbook -i inventory.ini pangolin.yml
```

## Next worth doing

1. Smoke-test PEM upload in a local compose stack against Traefik dynamic certs  
2. Re-design “enhanced tunnel types” against 1.21 site/client models  
3. Finish ODoH-for-WG clients as optional Ansible role under `deploy/`  
4. Optionally publish branch / GH repo under 88plug without any secrets from racknerd

## App-plus pass (2026-07-31)

Full `/app-plus` pipeline on base 1.21.1 + prior PEM/deploy work.

### Plus thesis

Pangolin OSS is the self-host identity-aware edge (proxy + WireGuard + Badger). Plus completes correctness and self-host gaps maintainers left open: session cookie handling, audit truth, geoblock multi-country, integration API, BYOC certs, OIDC redirect safety.

### Bugs fixed

| Item | Source | Notes |
|------|--------|-------|
| stripDuplicateSessions not deduping | OPEN PR #3445 | session cookie explosion / #2238 class |
| Request audit log row mix-up | OPEN PR #3459 / issue #3458 | ordering + UI |
| Audit log filter-attribute 6→1 scans | OPEN PR #3443 | applied after #3459 |
| Integration API site-resource lookup | OPEN PR #3510 / issue #2743 | + test |
| COUNTRY_IS_NOT multi-country | OPEN PR #3474 / issue #3432 | policy eval + UI |
| Blueprint certificates.domain UNIQUE | OPEN PR #3199 / issue #2937 | upsert path (EE createCertificate) |
| getTraefikConfig hot-path | OPEN PR #3191 | anySitesOnline out of loop |
| Regional locale detection | OPEN PR #3509 / issue #3480 | detectLocale helper |
| SSO redirect after expired session | CLOSED PR #3411 / issue #3001 | resource auth portal |
| Badger Remote-Groups header | CLOSED PR #3278 | downstream RBAC |
| OIDC post-auth open redirect | OPEN issue #3335 | `isSafePostAuthRedirect` |

### Features already in tree (prior commit)

- PEM custom certificate upload (BYOC / Cloudflare Origin) — relates to enhancement #3243
- `deploy/` Ansible bundle pinned to 1.21.1

### Skipped

| Item | Reason |
|------|--------|
| PR #3384 IdP validation | Already fixed upstream via `idpExistsForOrg` |
| PR #3368 wire test runner in CI | Large harness change; local tests need `@test/assert` path |
| Patch dep bumps (ncu) | `npm install` peer conflict after upgrade; reverted package.json |
| Full branch graveyard | Shallow clone (`--depth 1`); only tag tip present |
| Enhanced tunnel types (old 88plug) | Needs redesign on 1.21 models |
| RDP/CredSSP/Azure AD issues | Needs investigating / EE surface |
| Kubernetes operator etc. | Out of scope new product |

### Verify

- `npm ci` with **Node 22** (Node 26 fails better-sqlite3 prebuild on this host)
- `npm run set:oss && npm run set:sqlite && npx tsc --noEmit` → **exit 0**
- Full `npm run build` (next+esbuild) not run this pass

### DEPENDENCY AUDIT

- ✅ Baseline lockfile from 1.21.1 install: green
- ⚠️ Patch bumps available (next 16.2.11→16.2.12, axios, etc.) — **not applied** (peer resolve fail)
- 🔴 Major bumps: not evaluated for apply

## App-plus lap 2 (2026-07-31) — tunnel redesign + full research census

### Tunnel types redesign (from old `ebfc963`)

**Problem with the old port:** site `type` was overloaded with UX labels
(`secure-vpn` / `split-tunnel` / `privacy-gateway`) then coerced back to
`wireguard`. That breaks 1.21 assumptions (`sites.type` is only
`newt | wireguard | local`) and dropped `remoteSubnets` entirely in modern schema.

**New model** (`server/lib/tunnels/tunnelProfiles.ts`):

| Layer | Field | Values |
|-------|-------|--------|
| Transport | `sites.type` | `newt` \| `wireguard` \| `local` (unchanged) |
| Intent | `sites.tunnelProfile` | `standard` \| `secure-vpn` \| `split-tunnel` \| `privacy-gateway` |
| Routing | `sites.routingMode` | `selective` (default, targets only) \| `full-tunnel` (+ `0.0.0.0/0`) |

Profile → routing defaults:
- `secure-vpn` → full-tunnel
- `split-tunnel` → selective
- `privacy-gateway` → full-tunnel (UI copy points at edge ODoH/DNS; deploy notes in `deploy/odoh-wireguard-dns-notes.md`)
- `standard` → selective

**Code paths:**
- Schema + migration `1.21.2` (sqlite + pg)
- `createSite` / `updateSite` / `listSites`
- `gerbil/getConfig` + target create/update peer refresh
- Create-site UI tunnel profile select + SitesTable badge
- Pure unit test `server/lib/tunnels/tunnelProfiles.test.ts`

---

### Research census (this lap)

#### Open issues (20) — status vs plus

| # | Title | Plus status |
|---|-------|-------------|
| 3501 | Not able to connect to private Host | open / needs env |
| **3480** | Language error first enter | ✅ **#3509** applied lap1 |
| 3478 | Android connection failing | open / client |
| 3471 | IPv6 ISP mobile | open / network |
| **3458** | HTTP Request logs mix up rows | ✅ **#3459** applied lap1 |
| 3433 | Newt WG handshake after 1.20 | open / needs investigating |
| **3432** | country is not multi-country | ✅ **#3474** applied lap1 |
| 3430 | Android add user 0.20 | stale |
| 3428 | RDP Azure AD CredSSP | open / EE surface |
| 3360 | Domain optional in config | enhancement deferred |
| 3359 | Pass credentials via RDP | enhancement deferred |
| 3355 | Private HTTP Windows client | open |
| 3354 | Gerbil 0 proxy mappings 502 | open |
| **3335** | OIDC open redirect | ✅ `isSafePostAuthRedirect` lap1 |
| 3334 | /v1 API 404 | open / config |
| 3274 | Auto launch clients | feature deferred |
| 3272 | Browser RDP GNOME/Windows | open |
| 3271 | SSH key passphrase | enhancement deferred |
| 3255 | CredSSP InvalidToken | stale |
| 3254 | Shared policy rules order | enhancement deferred |

#### Closed issues (20) — sample of recent

Most COMPLETED by upstream (1.20–1.21): #3484, #3462, #3442, #3439, #3435, #3429, #3427, #3424, #3408, #3395, #3393, #3387, #3383, #3374, #3365, #3357.  
NOT_PLANNED kept for awareness: #3475 proxy chain POST, #3455 Olm hole punch org switch, #3444 health check collision, #3372 Android VPN under load.

#### Open PRs (20) — status vs plus

| # | Title | Plus status |
|---|-------|-------------|
| **3510** | site-resource lookup | ✅ lap1 |
| **3509** | regional locale | ✅ lap1 |
| 3506–3502 | docker/npm bumps | ⏭ dep policy |
| 3500 / 3481 | i18n | ⏭ |
| 3490 | npm-deps mega | ⏭ |
| **3474** | multi-country policy | ✅ lap1 |
| **3459** | audit log ordering | ✅ lap1 |
| 3448 | sqlite index parity | large, deferred |
| **3445** | stripDuplicateSessions | ✅ lap1 |
| **3443** | audit filter optimize | ✅ lap1 |
| 3384 | IdP validation | ⏭ already `idpExistsForOrg` |
| 3368 | test runner CI | ⏭ harness |
| **3199** | cert UNIQUE | ✅ lap1 |
| **3191** | traefik perf | ✅ lap1 |
| 3172 | response headers | feature, deferred |
| 3169 | in-app docs | conflict |
| 3160 | audit facet cache | conflicts with #3459 |

#### Closed unmerged PRs (20) — highlights

| # | Title | Plus status |
|---|-------|-------------|
| **3411** | SSO redirect after expiry | ✅ lap1 ⚡ |
| **3278** | Remote-Groups header | ✅ lap1 ⚡ |
| 3461 | resource rule validation | conflict / closed |
| rest | Crowdin / dependabot noise | skipped |

#### Branches (20 of 23 heads; dependabot excluded)

| Branch | PR | State | Note |
|--------|-----|-------|------|
| aig | — | none | no PR |
| backhaul | — | none | tunnel-related name; deep look later |
| cicd | — | none | |
| delete-account | — | none | |
| dev | #3505 | MERGED | = 1.21.1 tip |
| exit-node-reconnect | — | none | tunnel-related |
| feat/command-palette | #3188 | CLOSED | landed via 1.20 product |
| feat/remember-last-idp… | #3394 | MERGED | |
| fix/labels-dropdown-flicker | #3468 | MERGED | in 1.21.1 |
| fix/non-semver-version-error | #3407 | MERGED | |
| main | — | | release line |
| msg-delivery | — | none | |
| org-only-idp | — | none | related to IdP scoping |
| patch | — | none | |
| private-resource-page | — | none | |
| refactor/batch-status-requests | #3469 | MERGED | in 1.21.1 |
| resource-launcher | #3380 | MERGED | product in 1.20 |
| site-targets-auto-login | — | none | |
| ssh | — | none | EE surface |

**Branch mine boundary:** remote has **23 heads** total (4 dependabot). 19 non-bot listed above. No medium/large unmerged branch diffs adopted this lap (most value already in merged 1.20/1.21 product work). `backhaul` / `exit-node-reconnect` flagged for a future tunnel pass.

---

### Solved map (all plus work so far)

| Plus deliverable | Upstream issue/PR |
|------------------|-------------------|
| PEM cert upload | #3243 (enhancement BYOC) |
| stripDuplicateSessions | #3445, class of #2238 |
| Audit log ordering | #3459 / #3458 |
| Audit filter 6→1 | #3443 |
| Site-resource API | #3510 / #2743 |
| Multi-country geoblock | #3474 / #3432 |
| Cert UNIQUE upsert | #3199 / #2937 |
| Traefik hot-path | #3191 |
| Locale detection | #3509 / #3480 |
| SSO resource redirect | #3411 / #3001 |
| Badger Remote-Groups | #3278 |
| OIDC open redirect | #3335 |
| Tunnel profiles redesign | old 88plug `ebfc963` (not upstream) |

### Verify (lap 2)

- `npx tsc --noEmit` → exit 0
- `npx tsx server/lib/tunnels/tunnelProfiles.test.ts` → pass
