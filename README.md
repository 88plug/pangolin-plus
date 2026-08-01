> **[88plug/pangolin-plus](https://github.com/88plug/pangolin-plus)** — one monorepo, one product: the community **plus** of the **full Pangolin self-host stack**. We **mine** [fosrl/pangolin](https://github.com/fosrl/pangolin), [newt](https://github.com/fosrl/newt), [gerbil](https://github.com/fosrl/gerbil), [olm](https://github.com/fosrl/olm), and [badger](https://github.com/fosrl/badger) (issue/PR graveyards included) into **this tree** — not into separate `*-plus` repos.
>
> **Why & how we differ, matrices, port guide → [PANGOLIN_PLUS.md](PANGOLIN_PLUS.md).** Default branch: **`main`** on this product repo. Upstream fosrl is tracked as git remote **`upstream`** only (no PR conflict with fosrl).

<div align="center">
    <h2>
    <a href="https://pangolin.net/">
        <picture>
            <source media="(prefers-color-scheme: dark)" srcset="public/logo/word_mark_white.png">
            <img alt="Pangolin Logo" src="public/logo/word_mark_black.png" width="350">
        </picture>
    </a>
    </h2>
    <p><strong>pangolin-plus</strong> · self-host CE stack with the seams closed</p>
</div>

<div align="center">
  <h5>
      <a href="PANGOLIN_PLUS.md">Plus differences</a>
      <span> | </span>
      <a href="UPSTREAM.md">Upstream sync / port</a>
      <span> | </span>
      <a href="components/README.md">Components</a>
      <span> | </span>
      <a href="https://docs.pangolin.net/">Upstream docs</a>
      <span> | </span>
      <a href="https://github.com/fosrl/pangolin">fosrl/pangolin</a>
  </h5>
</div>

**Pangolin** is an open-source identity-based remote access platform on WireGuard® (reverse proxy + VPN + RBAC). Official product: [pangolin.net](https://pangolin.net).

**pangolin-plus** keeps that model and ships **one monorepo distribution**:

| Tree | Upstream | Plus |
|------|----------|------|
| Server (this root) | fosrl/pangolin **1.21.1** | BYOC PEM, tunnels, graveyard ports, … |
| [`components/newt`](components/newt) | fosrl/newt **1.15.0** | Reconnect/health/registration pack, prefer-local-routes |
| [`components/gerbil`](components/gerbil) | fosrl/gerbil **1.4.3** | **Mined** (URL sanitize, Stop once) |
| [`components/olm`](components/olm) | fosrl/olm **1.8.1** | **Mined** (WS re-register) |
| [`components/badger`](components/badger) | fosrl/badger **v1.5.0** | **Mined** (real-IP headers + tests) |

---

## Get started

### Develop / verify

```bash
# Server (npm path unchanged)
npm ci && npm run set:oss && npm run set:sqlite
npx tsc --noEmit && npm test

# All plus Go clients/edge binaries
make components-build    # newt + gerbil + olm → components/*/bin/
make components-test
```

### Full plus stack images

Clients need **plus-built** images/binaries for mined deltas — stock `fosrl/*` does not carry them.

```bash
# Local tags: pangolin-plus/{pangolin,gerbil,newt,olm}:local
make plus-images
# Optional push (your registry only):
# make plus-images-push PLUS_REGISTRY=ghcr.io/you/pangolin-plus PLUS_TAG=local

# Or compose (pangolin + gerbil + traefik v3.7 from this tree)
docker compose -f compose.plus.yaml build
docker compose -f compose.plus.yaml up -d

# Optional lab newt against the controller (needs NEWT_ID + NEWT_SECRET):
# export NEWT_ID=... NEWT_SECRET=...
# docker compose -f compose.plus.yaml --profile lab up -d
```

| Component | Role | How to run plus build |
|-----------|------|------------------------|
| pangolin | Controller | compose / `make plus-images` |
| gerbil | WG edge on controller | compose / `make plus-images` |
| newt | Site connector | site host binary or compose profile `lab` |
| olm | End-user client | `make -C components/olm local` (not a compose service) |
| badger | Traefik plugin | monorepo `components/badger` as localPlugins (not a long-running image) |

**When you must use plus-built newt/olm/badger:** any mined client/plugin fix (reconnect, registration, prefer-local-routes, real-IP, etc.). Stock `fosrl/*` or pangolin.net apps will not include those deltas. Binary names stay `newt`/`olm`/`gerbil`; image tags are `pangolin-plus/*`.

### Ansible VPS

```bash
cd deploy
cp inventory.ini.example inventory.ini
# configure domain / cert_mode / images (defaults: pangolin-plus/*:local, pull_images: false)
ansible-playbook -i inventory.ini pangolin.yml
```

Upstream stock images (override **names** + pull):  
`pangolin_image=fosrl/pangolin:1.21.1` `gerbil_image=fosrl/gerbil:latest` `pull_images=true`.  
Details: [deploy/README.md](deploy/README.md). Ops: [deploy/TROUBLESHOOTING.md](deploy/TROUBLESHOOTING.md).
---

## What plus adds (short)

**Server:** PEM BYOC · tunnel profiles · OIDC redirect guard · response headers · session/audit/geoblock/API fixes — full table in [PANGOLIN_PLUS.md](PANGOLIN_PLUS.md).

**Newt (mined into `components/newt`):** [#424](https://github.com/fosrl/newt/pull/424) registration chain · [#413](https://github.com/fosrl/newt/pull/413) reconnect WgData · [#412](https://github.com/fosrl/newt/pull/412) health races · [#357](https://github.com/fosrl/newt/pull/357) TLS state · prefer-local-routes default **true**.

**Not separate products:** any local `~/newt-plus` workspace is only a mining scratchpad; the product path is **`pangolin-plus/components/*`**.

---

## Upstream product (reference)

Browser reverse proxy, Newt sites, private resources, IdP/RBAC, resource launcher — see [docs.pangolin.net](https://docs.pangolin.net) and upstream READMEs.

Clients: [Mac](https://pangolin.net/downloads/mac) · [Windows](https://pangolin.net/downloads/windows) · [Linux](https://pangolin.net/downloads/linux) · [iOS](https://pangolin.net/downloads/ios) · [Android](https://pangolin.net/downloads/android) (or build `components/olm`).

---

## Licensing

Upstream dual license (AGPL-3 / Fossorial Commercial). This monorepo targets **OSS/CE** builds. See [LICENSE](LICENSE) and each component’s license file.

## Contributions

- Upstream: [CONTRIBUTING.md](CONTRIBUTING.md)
- Port one matrix row back to the matching **fosrl/** repo: [PANGOLIN_PLUS.md § Contribute by porting](PANGOLIN_PLUS.md#contribute-by-porting)

WireGuard is a registered trademark of Jason A. Donenfeld.
