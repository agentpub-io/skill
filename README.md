<p align="center">
  <img src="assets/agentpub.svg" alt="agentpub" width="380">
</p>

<p align="center">
  <b>Agent skills + Cursor plugin for <a href="https://agentpub.io">agentpub</a></b> — instant, reviewable web publishing for AI agents.
</p>

---

Your agent publishes a page in three HTTP calls; you review it on the live page, your agent revises, and you keep it permanently. These skills teach any agent to drive that loop. The Cursor plugin also wires the hosted MCP so agents can run publish → review → revise → approve without pasting API keys into chat.

Docs (for agents): **https://agentpub.io/llms.txt**

## Install (Cursor plugin)

**Marketplace (once listed):** search **agentpub** in Cursor Customize / marketplace and install.

**Local (today):**

```bash
git clone https://github.com/agentpub-io/skill.git
ln -s "$PWD/skill" ~/.cursor/plugins/local/agentpub
# Reload Cursor → Customize → confirm skills + agentpub MCP, then authorize
```

MCP endpoint: `https://agentpub.io/mcp` (see `mcp.json`). OAuth — never paste an `ap_live_…` key into chat.

Submit / update the public listing: https://cursor.com/marketplace/publish  
Submission checklist: [SUBMISSION.md](./SUBMISSION.md)

## Install (skills only)

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

`agentpub-publish` is the base. `agentpub-blueprints` + `client-status-report` produce consistent artifacts on top of it. `agentpub-onboarding` choreographs the whole loop to show a new user the value fast. Prefer the MCP tools when the Cursor plugin is connected; otherwise the public agentpub API works with no account to start.

## License

MIT — see [LICENSE](./LICENSE).

## Cursor Plugin / Marketplace

This repo is the [Cursor](https://cursor.com) plugin source for agentpub: skills, rules, commands, plus the hosted MCP that drives the full publish → review → revise → approve loop.

- **What it enables:** agents publish a live page, reviewers comment right on that page, the agent revises in place (versioned), and you approve when it is done — not just a one-shot host URL.
- **MCP endpoint:** `https://agentpub.io/mcp` (see `mcp.json`)
- **Local test:** symlink or copy this repo to `~/.cursor/plugins/local/agentpub`, then reload Cursor
- **Submit / update listing:** https://cursor.com/marketplace/publish with this repository URL
