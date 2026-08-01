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

Stock `fosrl/*` does **not** carry monorepo deltas. Build plus artifacts first:

```bash
# Binaries (site newt / user olm):
make components-build

# Controller + edge images (local tags):
make plus-images
# Load/transfer images to the VPS, then run the playbook with defaults.
# Or push then pull:
make plus-images-push PLUS_REGISTRY=ghcr.io/you/pangolin-plus PLUS_TAG=1.21.1-plus
```

```yaml
# pangolin.yml (or -e)
image_registry: ghcr.io/you/pangolin-plus
image_tag: 1.21.1-plus
pull_images: true
```

### Upstream stock fallback

Override **image names** (not only `image_registry`) and enable pull:

```yaml
pangolin_image: fosrl/pangolin:1.21.1
gerbil_image: fosrl/gerbil:latest
pull_images: true
```

The local-only guard rejects `pull_images: true` when `pangolin_image` / `gerbil_image` match `^pangolin-plus/` (Hub cannot supply those tags). Explicit `fosrl/*` names work even if `image_registry` stays at the default.

### What is *not* a deploy service

| Component | Where it runs | Plus build |
|-----------|---------------|------------|
| **newt** | Each **site** host | `make -C components/newt local` → `bin/newt` |
| **olm** | End-user devices | `make -C components/olm local` → `bin/olm` |
| **badger** | Traefik **localPlugins** | All playbooks copy monorepo `components/badger` when present; else clone **fosrl/badger v1.5.0**. Not a long-running image. |

You only get plus newt/olm/badger fixes when those hosts run artifacts built from this tree (or monorepo-sourced localPlugins).

Traefik is pinned to **v3.7** (matches `compose.plus.yaml` / installer).

### Preflight

When `pull_images: false` (default), playbooks `docker image inspect` `pangolin_image` and `gerbil_image` before `compose up`. Missing images fail with a pointer to `make plus-images` / load. Health wait fails the play if never healthy.

### Safe upgrade (`upgrade-pangolin.yml`)

Defaults rewrite compose images to **stock/registry** tags and pull:

| Var | Default |
|-----|---------|
| `pangolin_image` | `fosrl/pangolin:latest` |
| `gerbil_image` | `fosrl/gerbil:latest` |
| `traefik_image` | `traefik:v3.7` |
| `pull_images` | `true` |
| `resync_badger` | `true` (re-copy monorepo badger when present on control node) |

Plus local upgrade example:

```bash
ansible-playbook -i inventory.ini upgrade-pangolin.yml \
  -e pangolin_image=pangolin-plus/pangolin:local \
  -e gerbil_image=pangolin-plus/gerbil:local \
  -e pull_images=false
```

If on-disk compose already uses `pangolin-plus/*`, bare defaults refuse silent demote to stock
unless you pass `-e force_demote=true`.

Full plus re-deploy (compose + badger + config): re-run `pangolin.yml`.  
`pull_images=true` with `pangolin-plus/*` image names is rejected.

## PEM upload in the dashboard

pangolin-plus adds **Domain → Custom Certificate** so you can paste Origin PEMs after install instead of only at Ansible time. Files land under `traefik.certificates_path`.

## Ops docs in this folder

| File | Purpose |
|------|---------|
| `traefik-cookie-domain-fix.md` | Badger session cookie Domain= rewrite via Traefik plugin |
| `odoh-wireguard-dns-notes.md` | Force WG clients through ODoH (work in progress) |
| `playbook-simple.yml` | Minimal Ubuntu one-shot deploy |
| `playbook-debian-trixie.yml` | Debian Trixie variant |
| `upgrade-pangolin.yml` | Backup + image pin + optional pull/badger resync |

## Security

Never commit real `cert.pem`, `key.pem`, or inventory passwords. Use Ansible vault or env files with mode `0600`.
