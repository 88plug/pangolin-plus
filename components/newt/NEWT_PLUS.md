# Newt component (inside pangolin-plus)

This tree is **not** a standalone product. It is the **newt** component of
**[pangolin-plus](../../PANGOLIN_PLUS.md)** — mined from [fosrl/newt](https://github.com/fosrl/newt) **1.15.0**.

## Deltas mined in

| Upstream | Fix |
|----------|-----|
| [#424](https://github.com/fosrl/newt/pull/424) / [#423](https://github.com/fosrl/newt/issues/423) | Preserve pending WG registration chain |
| [#413](https://github.com/fosrl/newt/pull/413) / [#411](https://github.com/fosrl/newt/issues/411) | Fresh WgData on registration decode |
| [#412](https://github.com/fosrl/newt/pull/412) | Healthcheck status race guards |
| [#357](https://github.com/fosrl/newt/pull/357) ⚡ | netstack2 TLS ConnectionState |
| [#414](https://github.com/fosrl/newt/pull/414) ⚡ intent | `PreferLocalRoutes` default **true** (`--prefer-local-routes`) |

## Verify

```bash
make -C components/newt test
make -C components/newt local
```

See monorepo [PANGOLIN_PLUS.md](../../PANGOLIN_PLUS.md) for the full product matrix.
