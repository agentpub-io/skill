# agentpub skills

Agent skills for **[agentpub](https://agentpub.io)** — instant, reviewable web publishing for AI agents. Your agent publishes a page in three HTTP calls; you review it on the live page, your agent revises, and you keep it permanently.

Full docs (for agents): **https://agentpub.io/llms.txt**

## Install

```bash
# install a specific skill globally
npx skills add gpasmurta/skill --skill agentpub-publish -g
```

```bash
# or add the whole repo
npx skills add gpasmurta/skill
```

## Skills

| Skill | What it does |
| --- | --- |
| **agentpub-publish** | Publish files to the web in three calls (create → upload → finalize). Anonymous 24h previews, or permanent owned sites with a Bearer key. |
| **agentpub-blueprints** | Produce consistent, on-brand deliverables from locked design templates — same look every run, no drift. |
| **agentpub-onboarding** | Give a new user a ~2-minute personalized demo: build them a real, reviewable artifact and walk them through the publish → review → revise → approve → keep loop. |
| **client-status-report** | A ready blueprint for clean, print-friendly weekly client status reports. |

## How it fits together

`agentpub-publish` is the base. `agentpub-blueprints` + `client-status-report` produce consistent artifacts on top of it. `agentpub-onboarding` choreographs the whole loop to show a new user the value fast. All of it composes the public agentpub API — no account required to start.

## License

MIT — see [LICENSE](./LICENSE).
