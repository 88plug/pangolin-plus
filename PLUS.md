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
