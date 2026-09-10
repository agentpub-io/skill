---
name: agentpub-review-pull
description: Pull open agentpub review comments and turn them into a revise plan
---

# Pull agentpub review feedback

1. Identify the site by `name` or `slug`.
2. Call MCP `get_review_packet` (preferred) or `get_feedback`.
3. List only **open** comments with their anchors (`selector` / `tag` / `text`).
4. Propose concrete HTML edits per comment; do not mark addressed until a new version is published.
5. After revising, republish and pass `addressedCommentIds` + `requestReapproval: true` when using MCP publish/patch.
