> **newt-plus** — community **plus fork** of [fosrl/newt](https://github.com/fosrl/newt) **1.15.0**: *the site connector the maintainers had in flight for reconnect/healthcheck correctness, finished.* Registration chain preservation, fresh WgData on reconnect, healthcheck race guards, netstack TLS state forwarding, and **prefer-local-routes** by default so tunnel metrics do not steal LAN.
>
> **Why & how we differ → [NEWT_PLUS.md](NEWT_PLUS.md).** Each fix is an upstream **[port candidate](NEWT_PLUS.md#contribute-by-porting)**. Pairs with [pangolin-plus](../pangolin-plus/PANGOLIN_PLUS.md). Branch: `claude/newt-plus`.

# newt

[![GitHub release](https://img.shields.io/github/v/release/fosrl/newt)](https://github.com/fosrl/newt/releases)
[![Docker](https://img.shields.io/docker/pulls/fosrl/newt)](https://hub.docker.com/r/fosrl/newt)

**Newt** is the Pangolin site / network connector: WireGuard (native or netstack), holepunch, healthchecks, Docker labels, and the control websocket to your Pangolin server.

Official docs: [docs.pangolin.net](https://docs.pangolin.net).

## Get started (newt-plus)

```bash
cd ~/newt-plus
make test
make local
./bin/newt \
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
