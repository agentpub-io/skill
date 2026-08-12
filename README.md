<p align="center">
  <img src="assets/agentpub.svg" alt="agentpub" width="380">
</p>

<p align="center">
  <b>Agent skills for <a href="https://agentpub.io">agentpub</a></b> — instant, reviewable web publishing for AI agents.
</p>

---

Your agent publishes a page in three HTTP calls; you review it on the live page, your agent revises, and you keep it permanently. These skills teach any agent to drive that loop.

Docs (for agents): **https://agentpub.io/llms.txt**

## Install

```bash
# install a specific skill globally
npx skills add agentpub-io/skill --skill agentpub-publish -g
```

```bash
# or add the whole repo
npx skills add agentpub-io/skill
```

## Skills

| Skill | What it does |
| --- | --- |
| **agentpub-publish** | Publish files to the web in three calls (create → upload → finalize). Anonymous 24h previews, or permanent owned sites with a Bearer key. |
| **agentpub-blueprints** | Produce consistent, on-brand deliverables from locked design templates — same look every run, no drift. |
| **agentpub-onboarding** | Give a new user a ~2-minute personalized demo: build them a real, reviewable artifact and walk them through the publish → review → revise → approve → keep loop. |
| **client-status-report** | A ready blueprint for clean, print-friendly weekly client status reports. |

## How it fits together

`agentpub-publish` is the base. `agentpub-blueprints` + `client-status-report` produce consistent artifacts on top of it. `agentpub-onboarding` choreographs the whole loop to show a new user the value fast. It all composes the public agentpub API — no account required to start.

## License

MIT — see [LICENSE](./LICENSE).

## Cursor Plugin / Marketplace

This repo is also the [Cursor](https://cursor.com) plugin source for agentpub (skills + hosted MCP).

- **MCP endpoint:** `https://agentpub.io/mcp` (configured in `mcp.json`)
- **Local test:** symlink or copy this repo to `~/.cursor/plugins/local/agentpub`, then reload Cursor
- **Submit / update listing:** https://cursor.com/marketplace/publish with this repository URL

Modeled after [here.now](https://cursor.com/marketplace/here-now)’s marketplace plugin packaging.
