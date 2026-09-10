---
name: agentpub-publish
description: Publish a local HTML/static folder to agentpub as an owned, reviewable live URL
---

# Publish with agentpub

1. Confirm the folder has an `index.html` (and any assets).
2. Prefer the agentpub MCP `publish_site` tool with a stable `name`, `artifact.title` / `description`, and `review: true` when teammates will comment.
3. Default to an **owned** publish (OAuth / Bearer). Use anonymous only if the user explicitly wants a 24h throwaway.
4. Return the live URL and dashboard link. Confirm `authenticated: true` unless throwaway was requested.
5. If MCP is unavailable, follow the `agentpub-publish` skill / `https://agentpub.io/llms.txt` three-step create → upload → finalize flow.
