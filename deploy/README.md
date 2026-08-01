# Pangolin-plus deploy (Ansible)

Deploy the **pangolin-plus controller edge** (pangolin + gerbil + traefik) to a VPS.
Optional Cloudflare Origin Certificates. No secrets in-repo.

## Features

- Certificate modes: Let's Encrypt (default) or Cloudflare Origin Certificate
- Badger auth middleware (pre-downloaded locally)
- Rate limiting and optional MaxMind geoblocking
- Safe upgrades with backup/rollback (`upgrade-pangolin.yml`)
- Parameterized images: plus-built **or** upstream fosrl fallback
- Ops notes: Traefik cookie domain fix, ODoH-through-WireGuard DNS research

## Quick start

1. Copy and configure inventory:
   ```bash
   cp inventory.ini.example inventory.ini
   # Edit with VPS IP and auth
   ```

2. Configure `pangolin.yml` vars:
   - `base_domain`, `admin_email`
   - `cert_mode: "letsencrypt"` or `"cloudflare"`
   - For cloudflare: place `cert.pem` + `key.pem` next to the playbook
   - Images (see below)

3. Deploy:
   ```bash
   ansible-playbook -i inventory.ini pangolin.yml
   ```

4. Open `https://yourdomain.com/auth/initial-setup`

## Images

Playbooks default to **plus local tags** (same as `compose.plus.yaml` / `make plus-images`):

| Var | Default |
|-----|---------|
| `image_registry` | `pangolin-plus` |
| `image_tag` | `local` |
| `pangolin_image` | `{{ image_registry }}/pangolin:{{ image_tag }}` |
| `gerbil_image` | `{{ image_registry }}/gerbil:{{ image_tag }}` |
| `pull_images` | `false` (set `true` for registry pulls) |

### Plus-built (recommended for mined fixes)

```bash
# On a machine with this monorepo + Docker:
make plus-images
# Load/transfer images to the VPS, then run the playbook with defaults.
# Or push:
make plus-images plus-images-push PLUS_REGISTRY=ghcr.io/you/pangolin-plus PLUS_TAG=1.21.1-plus
```

```yaml
# pangolin.yml (or -e)
image_registry: ghcr.io/you/pangolin-plus
image_tag: 1.21.1-plus
pull_images: true
```

### Upstream stock fallback

```yaml
pangolin_image: fosrl/pangolin:1.21.1
gerbil_image: fosrl/gerbil:latest
pull_images: true
```

### What is *not* a deploy service

| Component | Where it runs | Plus build |
|-----------|---------------|------------|
| **newt** | Each **site** host | `make -C components/newt local` → `bin/newt` |
| **olm** | End-user devices | `make -C components/olm local` → `bin/olm` |
| **badger** | Traefik localPlugins | `pangolin.yml` copies monorepo `components/badger` when present; else clones **fosrl/badger v1.5.0**. Simple playbooks pin catalog plugin **v1.5.0**. |

You only get plus newt/olm fixes when those hosts run binaries built from this tree.

### Preflight

When `pull_images: false` (default), playbooks `docker image inspect` `pangolin_image` and `gerbil_image` before `compose up`. Missing images fail with a pointer to `make plus-images` / load. Health wait no longer ignores errors.

`pull_images: true` with `image_registry: pangolin-plus` is rejected (avoids accidental Docker Hub pull of a local-only name).
## PEM upload in the dashboard

pangolin-plus adds **Domain → Custom Certificate** so you can paste Origin PEMs after install instead of only at Ansible time. Files land under `traefik.certificates_path`.

## Ops docs in this folder

| File | Purpose |
|------|---------|
| `traefik-cookie-domain-fix.md` | Badger session cookie Domain= rewrite via Traefik plugin |
| `odoh-wireguard-dns-notes.md` | Force WG clients through ODoH (work in progress) |
| `playbook-simple.yml` | Minimal Ubuntu one-shot deploy |
| `playbook-debian-trixie.yml` | Debian Trixie variant |

## Security

Never commit real `cert.pem`, `key.pem`, or inventory passwords. Use Ansible vault or env files with mode `0600`.
