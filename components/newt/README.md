> **pangolin-plus · newt** — mined [fosrl/newt](https://github.com/fosrl/newt) **1.15.0** inside the [pangolin-plus](../../README.md) monorepo (not a separate `newt-plus` product). Deltas: [NEWT_PLUS.md](NEWT_PLUS.md) · product matrix: [PANGOLIN_PLUS.md](../../PANGOLIN_PLUS.md).

# newt

**Newt** is the Pangolin site / network connector: WireGuard (native or netstack), holepunch, healthchecks, Docker labels, and the control websocket to your Pangolin server.

Published plus builds: `ghcr.io/88plug/pangolin-plus/newt` · [Releases](https://github.com/88plug/pangolin-plus/releases) · `scripts/get-plus-newt.sh`.  
Upstream stock: [fosrl/newt](https://github.com/fosrl/newt) · [docs.pangolin.net](https://docs.pangolin.net).

## Build (from monorepo root)

```bash
make -C components/newt test
make -C components/newt local
./components/newt/bin/newt \
  --endpoint https://your-pangolin.example \
  --id <newt-id> \
  --secret <newt-secret>
```

### Plus defaults

| Flag / env | Default | Meaning |
|------------|---------|---------|
| `--prefer-local-routes` / `NEWT_PREFER_LOCAL_ROUTES` | **true** | Tunnel routes use high metric so overlapping LAN wins. Set `false` to restore upstream default behaviour. |

## What plus adds (short)

| Item | Upstream |
|------|----------|
| Preserve pending WG registration chain | [#424](https://github.com/fosrl/newt/pull/424) / [#423](https://github.com/fosrl/newt/issues/423) |
| Fresh WgData on registration (no stale hcStatus) | [#413](https://github.com/fosrl/newt/pull/413) / [#411](https://github.com/fosrl/newt/issues/411) |
| Healthcheck status race guards | [#412](https://github.com/fosrl/newt/pull/412) |
| netstack TLS ConnectionState forward | [#357](https://github.com/fosrl/newt/pull/357) ⚡ |
| Prefer local routes default on | [#414](https://github.com/fosrl/newt/pull/414) intent |

Full matrices: **[NEWT_PLUS.md](NEWT_PLUS.md)**.

## Upstream quick install

See upstream [README](https://github.com/fosrl/newt#readme) and [get-newt.sh](get-newt.sh) / Docker:

```bash
docker pull fosrl/newt:1.15.0
```

Build this fork’s image with the included `Dockerfile` and tag as you prefer.

## License

Same as upstream Newt (see [LICENSE](LICENSE)).
