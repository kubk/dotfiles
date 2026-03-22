# Codex MCP

Use `config.toml` for Codex MCP config.

## Global MCP

Put global servers in `~/.codex/config.toml`.

```toml
[mcp_servers.chrome-devtools]
command = "npx"
args = ["-y", "chrome-devtools-mcp@latest"]
```

## Local Per-Project MCP

Put project-only servers in `<repo>/.codex/config.toml`.

The repo must be trusted first. If needed:

```toml
[projects."/absolute/path/to/repo"]
trust_level = "trusted"
```

```toml
# <repo>/.codex/config.toml
[mcp_servers.bd1-local-db]
command = "npx"
args = ["-y", "@modelcontextprotocol/server-postgres", "postgresql://root:toor@localhost:5432/bd1"]
```

## Verify

Inside the repo:

```sh
cd /absolute/path/to/repo
codex mcp list
```

Outside the repo:

```sh
cd /some/other/project
codex mcp list
```

Expected result:
- In the target repo, you should see global MCPs and that repo's local MCPs.
- In other repos, you should only see global MCPs.

If the tool list looks stale, start a new Codex thread or restart Codex.
