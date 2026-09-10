# Cursor Marketplace submission

Repo: https://github.com/agentpub-io/skill  
Submit: https://cursor.com/marketplace/publish

## Checklist

- [x] `.cursor-plugin/plugin.json` exists with kebab-case `name` (`agentpub`)
- [x] `description`, `version`, `author`, `license`, `homepage`, `repository`, `keywords`, `logo`
- [x] `mcp.json` → `https://agentpub.io/mcp` (OAuth; no secrets in repo)
- [x] Skills under `skills/*/SKILL.md` with `name` + `description` frontmatter
- [x] Rules under `rules/` with frontmatter
- [x] Commands under `commands/` with frontmatter
- [x] Logo at `assets/agentpub.svg` (relative path)
- [x] `README.md` documents install + MCP purpose
- [x] Public GitHub repository
- [ ] Submitted at cursor.com/marketplace/publish (manual — Scott)
- [ ] Cursor team review / listing live (SearchPlugins currently finds nothing)

## Local test

```bash
ln -s "$PWD" ~/.cursor/plugins/local/agentpub
# Reload Cursor window, then open Customize and confirm skills + agentpub MCP
```

## Notes

- Do not embed API keys or OAuth client secrets in this repo.
- MCP uses dynamic client registration against `https://agentpub.io`.
