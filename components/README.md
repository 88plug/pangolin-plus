# pangolin-plus components (single product)

This directory is the **ecosystem half of pangolin-plus**. We do **not** ship separate
`newt-plus` / `olm-plus` products. We **mine** upstream [fosrl](https://github.com/fosrl)
repos (and any useful fork PRs), apply plus deltas here, and build one distribution.

| Component | Upstream | Base tag | Plus status |
|-----------|----------|----------|-------------|
| **newt/** | [fosrl/newt](https://github.com/fosrl/newt) | **1.15.0** | **Mined** — registration chain, reconnect WgData, healthcheck races, TLS ConnectionState, prefer-local-routes default |
| **gerbil/** | [fosrl/gerbil](https://github.com/fosrl/gerbil) | **1.4.3** | **Mined** — remoteConfigURL sanitize, Stop stopOnce |
| **olm/** | [fosrl/olm](https://github.com/fosrl/olm) | **1.8.1** | **Mined** — always re-register on WS reconnect |
| **badger/** | [fosrl/badger](https://github.com/fosrl/badger) | **v1.5.0** | **Mined** — trusted-hop real-IP headers + unit tests |
| *(server root)* | [fosrl/pangolin](https://github.com/fosrl/pangolin) | **1.21.1** | **Mined** — see [PANGOLIN_PLUS.md](../PANGOLIN_PLUS.md) |

Nested `.git` dirs are removed so history is the single `claude/pangolin-plus` branch.

### Build

```bash
# From repo root
make -C components/newt local test
make -C components/gerbil local    # if Makefile exists
# or use compose.plus.yaml build contexts
```

### Provenance of newt deltas

Mined open/closed PRs: #424, #413, #412, #357; #414 intent → `PreferLocalRoutes` default true.
Details: [newt/NEWT_PLUS.md](newt/NEWT_PLUS.md) (component changelog).
