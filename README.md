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
# Server
npm ci && npm run set:oss && npm run set:sqlite
npx tsc --noEmit && npm test

# Newt (in monorepo)
make newt-test && make newt-build
# → components/newt/bin/newt
```

### Compose (build from this tree)

```bash
docker compose -f compose.plus.yaml build
docker compose -f compose.plus.yaml up -d
```

### Ansible VPS

```bash
cd deploy
cp inventory.ini.example inventory.ini
# configure domain / cert_mode
ansible-playbook -i inventory.ini pangolin.yml
```

Ops notes: [deploy/TROUBLESHOOTING.md](deploy/TROUBLESHOOTING.md).

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
