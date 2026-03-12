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
