# Pangolin-plus deploy (Ansible)

Deploy **fosrl/pangolin 1.21.1** (or the pangolin-plus image you build) to a VPS with optional Cloudflare Origin Certificates.

Bundled from prior `racknerd-pangolin` public playbooks + simple single-file playbooks. No secrets included.

## Features

- Certificate modes: Let's Encrypt (default) or Cloudflare Origin Certificate
- Badger auth middleware (pre-downloaded locally)
- Rate limiting and optional MaxMind geoblocking
- Safe upgrades with backup/rollback (`upgrade-pangolin.yml`)
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

3. Deploy:
   ```bash
   ansible-playbook -i inventory.ini pangolin.yml
   ```

4. Open `https://yourdomain.com/auth/initial-setup`

## Image pin

Playbooks default to `fosrl/pangolin:1.21.1`. After you build pangolin-plus, retag:

```bash
docker build -t yourregistry/pangolin-plus:1.21.1 --build-arg BUILD=oss .
# then set image: yourregistry/pangolin-plus:1.21.1 in the compose task
```

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
