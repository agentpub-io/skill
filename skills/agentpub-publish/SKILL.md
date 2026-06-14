---
name: agentpub-publish
description: Use when asked to publish, host, deploy, or share an HTML page, report, dashboard, visualization, or static files to a live URL, or when agentpub is mentioned. Static sites only (no server-side compute).
compatibility: Any agent or shell that can make HTTP requests (curl or fetch). No install required; an optional MCP endpoint is at https://agentpub.io/mcp.
metadata:
  author: agentpub
  version: "1.0"
  homepage: https://agentpub.io
---

# agentpub publishing

agentpub turns local HTML/static files into a live URL via a three-step API: create → upload → finalize. Base: `https://agentpub.io`.

## When to use / when NOT

Use to put static HTML, CSS, JS, images, PDFs, or other static assets online fast. Do NOT use for server-side compute, databases, or dynamic backends — served sites are static only.

## The three calls

1. Create — declare each file with its **exact byte size**:

```bash
curl -sX POST https://agentpub.io/api/v1/publish \
  -H 'content-type: application/json' \
  -d '{"files":[{"path":"index.html","size":1234,"contentType":"text/html"}]}'
```

Returns `upload.versionId`, `upload.uploads[]` (each `{path, method:"PUT", url}`), `upload.finalizeUrl`. Anonymous responses also include `claimToken`, `claimUrl`, `warning`.

2. Upload — PUT each file's bytes to its presigned `url`, sending content-type:

```bash
curl -sX PUT '<upload.uploads[].url>' \
  -H 'content-type: text/html' --data-binary @index.html
```

3. Finalize — flip it live:

```bash
curl -sX POST '<upload.finalizeUrl>' \
  -H 'content-type: application/json' \
  -d '{"versionId":"<upload.versionId>"}'
```

Live at `https://{slug}.agentpub.io/`.

## Anonymous vs owned

- **No auth** → 24h site + a one-time `claimToken`/`claimUrl`. **SURFACE the `claimUrl` to the user IMMEDIATELY and prominently — it is shown only once and is the only way to keep the site past 24h.** Never log or paste the `claimToken` anywhere else.
- **`Authorization: Bearer $AGENTPUB_API_KEY`** → permanent, account-owned site. Get a key via the claim flow, or: `POST /api/auth/agent/request-code` `{"email":"..."}` → `POST /api/auth/agent/verify-code` `{"email":"...","code":"..."}` returns `apiKey`.

## Updating

`PUT /api/v1/publish/{slug}` (same body shape as create). Authorize with `{"claimToken":"..."}` in the body (anonymous) or the owner's `Bearer` header. Include a per-file `hash` (sha256, lowercase hex — `shasum -a 256 file`) so files whose hash matches the live version skip upload (returned under `upload.carried`); only changed files get presigned URLs. Then finalize as above. Dedup only works when hashes were also sent on the version being compared against — send `hash` on every publish including the first.

## Quick reference

| Action         | Call                                                                                      |
| -------------- | ----------------------------------------------------------------------------------------- |
| Site status    | `GET /api/v1/sites/{slug}`                                                                |
| List my sites  | `GET /api/v1/sites` (Bearer)                                                              |
| Versions       | `GET /api/v1/publish/{slug}/versions` (Bearer or `?claimToken=`)                          |
| Rollback       | `POST /api/v1/publish/{slug}/rollback` `{"versionId":"..."}`                              |
| Delete         | `DELETE /api/v1/publish/{slug}` (Bearer, or `{"claimToken":"..."}`)                       |
| List keys      | `GET /api/v1/keys` (Bearer)                                                               |
| Revoke key     | `DELETE /api/v1/keys/{id}` (Bearer)                                                       |
| Enable review  | `POST /api/v1/publish/{slug}/review` `{"enabled":true}` (Bearer) — MCP `enable_review`    |
| Get feedback   | `GET /api/v1/sites/{slug}/comments` → `{slug, approved, comments[]}` — MCP `get_feedback` |
| Mark addressed | `POST /api/v1/sites/{slug}/comments/{id}/addressed` (Bearer) — MCP `mark_addressed`       |

Enabling review mode turns on a feedback widget on the served page where reviewers leave page-level comments and approve. Comments can target a specific element via an anchor `{selector, tag, text}`, surfaced by `get_feedback` so the agent can locate and edit that exact element.

## Applying review feedback

Run this loop whenever asked to "apply the agentpub comments for `{slug}`":

1. **Fetch comments** — MCP `get_feedback(slug)` or `GET /api/v1/sites/{slug}/comments` (Bearer). Returns `{slug, approved, approvedVersionId, comments[]}`. Each comment has `status` (`"open"` | `"addressed"`), `body` (the requested change), and `anchor: {selector, tag, text} | null`.

2. **Filter** — work only on comments where `status === "open"`.

3. **Fetch the live page source** — `GET https://{slug}.agentpub.io/` (or whichever file the comment targets). **Strip the review widget before editing**: the served HTML of a review-enabled site has a block injected immediately before `</body>` that begins with `<button id="apb-approve-top"`. Remove everything from that `<button>` to and including `</body>`, then append a clean `</body>` — do NOT bake the widget back into the published source.

4. **Apply each change** — for comments with an anchor, locate the element by matching `tag` + `text` first; use `selector` to disambiguate when multiple elements match. For anchorless comments, apply the change to the page as a whole. Edit the in-memory source.

5. **Republish** — standard three-call flow against `PUT /api/v1/publish/{slug}` (Bearer `$AGENTPUB_API_KEY`): declare files with exact byte sizes and sha256 hashes → upload changed files → finalize.

6. **Mark addressed** — for each comment you handled: MCP `mark_addressed(slug, commentId)` or `POST /api/v1/sites/{slug}/comments/{commentId}/addressed` (Bearer). Call after a successful finalize.

## Gotchas

- `size` is validated for format and limits at create (must be an integer, ≤ 25 MB), but a mismatch between declared and actual bytes is not enforced at upload — still declare exact bytes (`wc -c < file`) because the manifest is recorded metadata.
- Send the `content-type` on the upload PUT — R2 records it and serves it back.
- Finalize `409` means a declared file didn't upload — re-PUT that file, then re-finalize.
- `429` → respect the `Retry-After` header before retrying.
- Anonymous sites show a claim badge; claiming (via `claimUrl`) removes it.

Full reference: `https://agentpub.io/llms.txt` and `https://agentpub.io/openapi.json`.
