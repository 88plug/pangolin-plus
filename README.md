# pangolin-plus

**Self-host [Pangolin](https://pangolin.net) with the seams closed.**

One monorepo. One product. We take [fosrl/pangolin](https://github.com/fosrl/pangolin) **plus** its companions (newt, gerbil, olm, badger), mine the issue/PR graveyards, and ship the result as **published images and client binaries** — not five separate forks.

| | |
|---|---|
| **Latest release** | [`v1.21.1-plus`](https://github.com/88plug/pangolin-plus/releases/tag/v1.21.1-plus) |
| **Images** | `ghcr.io/88plug/pangolin-plus/{pangolin,gerbil,newt,olm}` |
| **Full delta matrix** | [PANGOLIN_PLUS.md](PANGOLIN_PLUS.md) |
| **Upstream docs** | [docs.pangolin.net](https://docs.pangolin.net) |

**Version source of truth:** git tag / GHCR image tag `vX.Y.Z-plus` (e.g. `v1.21.1-plus`). Plus-release rewrites `APP_VERSION` in [`server/lib/consts.ts`](server/lib/consts.ts) to `X.Y.Z-plus` (no leading `v`). Root `package.json` `"version": "0.0.0"` is a private monorepo placeholder only.

---

## Install (users)

### 1. Controller + edge (Docker)

```bash
export TAG=v1.21.1-plus

export PANGOLIN_IMAGE=ghcr.io/88plug/pangolin-plus/pangolin:${TAG}
export GERBIL_IMAGE=ghcr.io/88plug/pangolin-plus/gerbil:${TAG}
# optional site-in-compose lab profile:
# export NEWT_IMAGE=ghcr.io/88plug/pangolin-plus/newt:${TAG}

docker compose -f compose.plus.yaml pull
docker compose -f compose.plus.yaml up -d --no-build
```

### 2. Site client (newt) and user client (olm)

```bash
# Checksum-verified from GitHub Releases (VERSION with or without leading v)
curl -fsSL https://raw.githubusercontent.com/88plug/pangolin-plus/main/scripts/get-plus-newt.sh \
  | VERSION=v1.21.1-plus sh

curl -fsSL https://raw.githubusercontent.com/88plug/pangolin-plus/main/scripts/get-plus-olm.sh \
  | VERSION=v1.21.1-plus sh

newt --version   # → Newt version 1.21.1-plus
```

Gerbil usually runs as the edge **container** above. Optional host binary: `scripts/get-plus-gerbil.sh` (linux only).

### 3. Or Ansible on a VPS

```bash
cd deploy
cp inventory.ini.example inventory.ini   # set domain / secrets
# defaults are plus-local; for published images:
#   image_registry=ghcr.io/88plug/pangolin-plus image_tag=v1.21.1-plus pull_images=true
ansible-playbook -i inventory.ini pangolin.yml
```

Details: [deploy/README.md](deploy/README.md).

---

## Why not stock fosrl?

| You run | You get |
|---------|---------|
| **GHCR / get-plus / this monorepo** | Full **plus** stack — mined client + plugin + server fixes |
| Stock `fosrl/*` or pangolin.net downloads | Protocol-compatible, **without** plus deltas |

Plus clients and the controller talk the same WireGuard/control protocol as upstream. The difference is the **code inside** the binaries and images.

**Badger** (Traefik auth plugin) is not a long-running image. Plus real-IP headers ship from `components/badger` via compose/Ansible **localPlugins**.

---

## What’s improved (app-plus mining)

All of this lives under **this tree** and is what `v1.21.1-plus` builds and publishes.

| Piece | Base | In the release |
|-------|------|----------------|
| **Server** (repo root) | pangolin 1.21.1 | PEM BYOC, tunnel profiles, OIDC redirect guard, headers, session/audit/geoblock/API graveyard ports |
| **newt** | 1.15.0 | Registration chain, reconnect WgData, health races, TLS ConnectionState, **prefer-local-routes default on** |
| **gerbil** | 1.4.3 | remoteConfig URL sanitize, idempotent Stop |
| **olm** | 1.8.1 | Always re-register on WebSocket reconnect |
| **badger** | v1.5.0 | Trusted-hop real client IP (CF → X-Real-IP → XFF) + tests |

Published newt images are built from `components/newt` (prefer-local-routes default on, reconnect pack, etc.).

Deep table, provenance, and port-back guide: **[PANGOLIN_PLUS.md](PANGOLIN_PLUS.md)**.

---

## Develop

```bash
npm ci && npm run set:oss && npm run set:sqlite
npx tsc --noEmit && npm test

make components-build      # newt / gerbil / olm → components/*/bin/
make components-test
make plus-guards-selftest  # scripts + ansible syntax + guards
```

Local images (no GHCR):

```bash
make plus-images           # pangolin-plus/*:local
docker compose -f compose.plus.yaml up -d
```

---

## Cut a release (maintainers)

```bash
# Optional dry-run (no push, no GitHub Release):
#   gh workflow run "Plus Release" -f tag=v1.21.2-plus -f dry_run=true

git tag v1.21.2-plus
git push origin v1.21.2-plus
# → multi-arch GHCR images + Release assets
```

Tag form: `vX.Y.Z-plus` (RC: `vX.Y.Z-plus.rc.1`). Workflow: [`.github/workflows/plus-release.yml`](.github/workflows/plus-release.yml).

---

## Layout

```
pangolin-plus/
  (root)              Pangolin CE server
  components/newt     Site connector (mined)
  components/gerbil   WG edge (mined)
  components/olm      User client (mined)
  components/badger   Traefik plugin (mined)
  compose.plus.yaml   Lab / published-image compose
  deploy/             Ansible
  scripts/get-plus-*  Client installers
```

Upstream fosrl is git remote **`upstream`** for sync only. Product home is **this** repo’s `main`.

---

## License

Upstream dual license (AGPL-3 / Fossorial Commercial). This monorepo targets OSS/CE builds. See [LICENSE](LICENSE) and each component’s license.

Port a delta back to fosrl: [PANGOLIN_PLUS.md § Contribute by porting](PANGOLIN_PLUS.md#contribute-by-porting).

WireGuard is a registered trademark of Jason A. Donenfeld.
