> **pangolin-plus** — community **plus fork** of [fosrl/pangolin](https://github.com/fosrl/pangolin) (base **1.21.1**): *the self-host OSS edge the maintainers had in flight, finished.* BYOC / Cloudflare Origin PEM certs, WireGuard tunnel profiles (full- vs split-tunnel), OIDC open-redirect hardening, correctness fixes mined from the issue/PR **graveyard**, and a real Ansible deploy path — on top of upstream Pangolin CE.
>
> **Why & how we differ, with full feature / bug / community matrices → [PANGOLIN_PLUS.md](PANGOLIN_PLUS.md).** Everything here is built to be upstream-acceptable: each fix/feature is an isolated **[port candidate](PANGOLIN_PLUS.md#contribute-by-porting)** you can carry back to fosrl/pangolin as a focused PR. Branch: `claude/pangolin-plus`.

<div align="center">
    <h2>
    <a href="https://pangolin.net/">
        <picture>
            <source media="(prefers-color-scheme: dark)" srcset="public/logo/word_mark_white.png">
            <img alt="Pangolin Logo" src="public/logo/word_mark_black.png" width="350">
        </picture>
    </a>
    </h2>
</div>

<div align="center">
  <h5>
      <a href="https://pangolin.net/">Website</a>
      <span> | </span>
      <a href="https://docs.pangolin.net/">Documentation</a>
      <span> | </span>
      <a href="PANGOLIN_PLUS.md">Plus differences</a>
      <span> | </span>
      <a href="mailto:contact@pangolin.net">Contact (upstream)</a>
  </h5>
</div>

<div align="center">

[![Discord](https://img.shields.io/discord/1325658630518865980?logo=discord&style=flat-square)](https://discord.gg/HCJR8Xhme4)
[![Docker](https://img.shields.io/docker/pulls/fosrl/pangolin?style=flat-square)](https://hub.docker.com/r/fosrl/pangolin)
![Stars](https://img.shields.io/github/stars/fosrl/pangolin?style=flat-square)

</div>

**Pangolin** is an open-source, identity-based remote access platform built on WireGuard®. It combines reverse-proxy and VPN capabilities: browser-based access to web apps and client-based access to private resources with NAT traversal and granular access control.

**pangolin-plus** is the same product surface for **self-host Community Edition**, with the operator-facing seams closed (see [PANGOLIN_PLUS.md](PANGOLIN_PLUS.md)).

---

## Get started (pangolin-plus)

### 1. Upstream quick install (still the default path)

- [Self-host quick install](https://docs.pangolin.net/self-host/quick-install)
- [DigitalOcean marketplace](https://marketplace.digitalocean.com/apps/pangolin-ce-1?refcode=edf0480eeb81)
- Cloud: [app.pangolin.net](https://app.pangolin.net)

### 2. Plus-aware VPS deploy (Ansible)

From this repo’s [`deploy/`](deploy/) tree (no secrets included):

```bash
cd deploy
cp inventory.ini.example inventory.ini
# set base_domain, admin_email, cert_mode (letsencrypt | cloudflare)
# for cloudflare: place cert.pem + key.pem next to the playbook
ansible-playbook -i inventory.ini pangolin.yml
```

Images are pinned to **fosrl/pangolin:1.21.1**. After you build this fork’s image, retag and swap the compose image name.

Ops notes: [deploy/TROUBLESHOOTING.md](deploy/TROUBLESHOOTING.md) (e.g. integration API 404 / [#3334](https://github.com/fosrl/pangolin/issues/3334)).

### 3. Develop this fork from source

```bash
# Node 22 recommended (better-sqlite3 prebuilds)
npm ci
npm run set:oss && npm run set:sqlite
cp -n config/config.example.yml config/config.yml   # gitignored
npx tsc --noEmit
npm test
# npm run build   # next + server bundle
```

Migrations added by plus: `1.21.2` (tunnel columns), `1.21.3` (request/response headers).

Full verify matrix: [PANGOLIN_PLUS.md#build--verify](PANGOLIN_PLUS.md#build--verify).

---

## What plus adds (short)

| Area | Plus change |
|------|-------------|
| TLS | PEM upload for BYOC / Cloudflare Origin ([#3243](https://github.com/fosrl/pangolin/issues/3243)) |
| WireGuard sites | Tunnel profiles + full-tunnel vs selective AllowedIPs |
| Auth | OIDC open-redirect guard ([#3335](https://github.com/fosrl/pangolin/issues/3335)); SSO resource redirect ([#3411](https://github.com/fosrl/pangolin/pull/3411)) |
| Correctness | Session cookie dedupe, audit log fixes, geoblock multi-country, site-resource API, … |
| Resources | Custom **response** headers ([#3172](https://github.com/fosrl/pangolin/pull/3172)) |
| DX | `npm test` runner ([#3368](https://github.com/fosrl/pangolin/pull/3368)) |

Full tables (features, bugs, skips, branch graveyard): **[PANGOLIN_PLUS.md](PANGOLIN_PLUS.md)**.

---

## Upstream product (unchanged story)

Pangolin remains the identity-aware remote access platform described by Fossorial. Summary:

### Connect remote networks with sites and NAT traversal

Site connectors (Newt / WireGuard / local) open outbound tunnels so you can reach resources without public IPs or open ports. WireGuard-based, segmented, with health and status history.

### Browser-based reverse proxy access

HTTPS apps, VNC, RDP, SSH in the browser, SSO, PIN / OTP / geoblock / allow-lists, Traefik-backed routing and TLS.

### Client-based private resource access

Pangolin clients reach private services and CIDRs with peer-to-peer NAT traversal and DNS aliases.

### Users, roles, and resource launcher

Built-in users or your IdP, RBAC, audit logs, and the 1.20+ resource launcher / command palette.

Official docs: [docs.pangolin.net](https://docs.pangolin.net).

### Download clients

- [Mac](https://pangolin.net/downloads/mac) · [Windows](https://pangolin.net/downloads/windows) · [Linux](https://pangolin.net/downloads/linux) · [iOS](https://pangolin.net/downloads/ios) · [Android](https://pangolin.net/downloads/android)

---

## Deployment options

| Option | Notes |
|--------|--------|
| **Pangolin Cloud** | Managed — [app.pangolin.net](https://app.pangolin.net) |
| **Self-host CE (upstream)** | AGPL-3 — official installer |
| **Self-host CE (this fork)** | AGPL-3 + plus deltas — `claude/pangolin-plus` + optional [`deploy/`](deploy/) |
| **Self-host EE** | Fossorial Commercial License — not the default build of this fork (`npm run set:oss`) |

---

## Licensing

Upstream Pangolin is dual-licensed under AGPL-3 and the [Fossorial Commercial License](https://pangolin.net/fcl). This plus fork stays on the **OSS / CE** build path. Commercial inquiries: [contact@pangolin.net](mailto:contact@pangolin.net).

## Contributions

- Upstream guidelines: [CONTRIBUTING.md](./CONTRIBUTING.md)
- Porting a plus fix back to fosrl/pangolin: [PANGOLIN_PLUS.md § Contribute by porting](PANGOLIN_PLUS.md#contribute-by-porting)

WireGuard is a registered trademark of Jason A. Donenfeld.
