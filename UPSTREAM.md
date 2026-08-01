# Upstream workflow (goose-plus style)

**This repo is the product.** Default branch `main` is pangolin-plus.

| Remote | URL | Role |
|--------|-----|------|
| `origin` | `https://github.com/88plug/pangolin-plus.git` | **Our** product — push/PR here |
| `upstream` | `https://github.com/fosrl/pangolin.git` | Upstream server only — fetch/sync, never force-push |

Companion upstreams (mined into `components/`):

- https://github.com/fosrl/newt
- https://github.com/fosrl/gerbil
- https://github.com/fosrl/olm
- https://github.com/fosrl/badger

## Why not a GitHub fork of fosrl/pangolin?

GitHub forks put PRs and Issues on the upstream network by default. A **standalone** `88plug/pangolin-plus` repo (same layout as [88plug/goose-plus](https://github.com/88plug/goose-plus)) keeps:

- Issues / PRs / Discussions on **our** product
- No accidental “open PR against fosrl” from this clone’s origin
- Clear identity: monorepo product vs single-repo CE server

## Sync fosrl server into our tree

```bash
git fetch upstream
# Inspect
git log --oneline HEAD..upstream/main | head
# Merge or rebase carefully (components/ is ours)
git merge upstream/main
# or cherry-pick specific release tags
git merge v1.21.x   # when tags exist on upstream
```

After merge: re-run `npm run set:oss && npm run set:sqlite`, `npx tsc --noEmit`, `npm test`, and `make components-test`.

## Port a plus fix **back** to fosrl

Plus deltas are written to be upstream-acceptable. Typical path:

1. Identify the server-only file(s) under `server/` / `src/` (not `components/`).
2. In a **separate** clone of fosrl/pangolin (or a branch that only tracks `upstream`), cherry-pick or re-apply the minimal diff.
3. Open the PR against **fosrl/pangolin**, not against this repo.

Companion ports (newt/gerbil/olm/badger) go to the matching fosrl repo from the delta in `components/<name>/`.

## Local branches

| Branch | Meaning |
|--------|---------|
| `main` | Product default (what we ship) |
| `claude/pangolin-plus` | Historical work name; may alias `main` during transition |
| `upstream-main` (optional) | Tracking tip of `upstream/main` for comparisons |

```bash
# Refresh optional tracking branch
git fetch upstream
git branch -f upstream-main upstream/main
```

## Compare

```bash
# Our tip vs fosrl main
git fetch upstream
git log --oneline upstream/main..main | head -40
```
