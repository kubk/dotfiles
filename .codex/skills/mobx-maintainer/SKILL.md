---
name: "mobx-maintainer"
description: "Use when working in the MobX monorepo on maintainer tasks such as CI, local test/build workflow, clean checkout or worktree setup, and avoiding regressions in local developer ergonomics."
---

# MobX Maintainer

Use this skill for repository-maintenance work in the MobX monorepo.

## Local test bootstrap

- On a clean checkout or a new git worktree, assume package `dist` artifacts may be missing.
- If local tests need built package output, run `yarn lerna run build:test` once before `yarn test`.

## Useful commands

- Bootstrap test builds once: `yarn lerna run build:test`
- Run Jest after bootstrap: `yarn test -i`

## Changesets

- For changes to a published package, add a changeset file in `.changeset/` unless the change is docs-only, test-only, or CI-only.
- Do not run `yarn changeset` interactively. Create the file directly with a short unique kebab-case name such as `.changeset/fresh-mice-walk.md`.
- Use this format:

```md
---
"mobx": patch
---

Short release note in one sentence.
```

- Replace `"mobx"` with the affected package name such as `"mobx-react"` or `"mobx-react-lite"`.
- Use `patch` for fixes and small exports, `minor` for backward-compatible features, and `major` for breaking changes.
