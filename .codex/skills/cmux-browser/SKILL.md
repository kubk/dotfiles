---
name: "cmux-browser"
description: "Use when the user wants browser automation through the cmux browser CLI instead of Chrome DevTools tools. Covers opening pages, waiting, DOM interaction, inspection, JavaScript eval, cookies/storage/state, tabs, dialogs, downloads, and debugging with snapshots or screenshots."
---

# Cmux Browser

Use this skill when browser work should happen through the `cmux browser` CLI.

## Workflow

1. Prefer Bash commands that call `cmux browser` directly.
2. Open or identify a target surface, then keep reusing that surface ID.
3. After `open` or `navigate`, run `wait --load-state complete` before interacting.
4. Use `snapshot` for DOM/text inspection and `screenshot --out ...` when visual output matters.
5. For failures, collect console errors plus a screenshot or snapshot before retrying.

## Rules

- Do not use Chrome DevTools tools for work that this CLI can handle.
- Do not use `--snapshot-after` on commands that include a URL; run a separate `snapshot` instead.
- If `snapshot` returns little or nothing, switch to `screenshot` immediately.
- Prefer structured getters like `get title`, `get url`, `get text`, and `is visible` when you need machine-readable checks.

## Common Commands

```bash
cmux browser open https://example.com
cmux browser identify
cmux browser surface:2 wait --load-state complete --timeout-ms 15000
cmux browser surface:2 click "button[type='submit']"
cmux browser surface:2 fill "#email" --text "ops@example.com"
cmux browser surface:2 snapshot --interactive --compact
cmux browser surface:2 screenshot --out /tmp/cmux-page.png
cmux browser surface:2 eval "document.title"
cmux browser surface:2 console list
cmux browser surface:2 errors list
```

## Common Patterns

```bash
cmux browser open https://example.com/login
cmux browser surface:2 wait --load-state complete --timeout-ms 15000
cmux browser surface:2 fill "#email" --text "ops@example.com"
cmux browser surface:2 fill "#password" --text "$PASSWORD"
cmux browser surface:2 click "button[type='submit']"
cmux browser surface:2 wait --text "Welcome"
cmux browser surface:2 is visible "#dashboard"
```
