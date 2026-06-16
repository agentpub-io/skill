---
name: agentpub-publish
description: Use when asked to publish, host, deploy, or share an HTML page, report, dashboard, visualization, or static files to a live URL, or when agentpub is mentioned. Static sites only (no server-side compute).
compatibility: Any agent or shell that can make HTTP requests (curl or fetch). No install required; an optional MCP endpoint is at https://agentpub.io/mcp, and a reference helper script ships at agentpub.sh.
metadata:
  author: agentpub
  version: "1.1"
  homepage: https://agentpub.io
---

# agentpub publishing

agentpub turns local HTML/static files into a live URL via a three-step API: create → upload → finalize. Base: `https://agentpub.io`.

## When to use / when NOT

Use to put static HTML, CSS, JS, images, PDFs, or other static assets online fast. Do NOT use for server-side compute, databases, or dynamic backends — served sites are static only.

## Step 0 — resolve a key and authenticate by default (DO THIS FIRST)

**The single most common mistake is publishing anonymously by accident** — that creates a throwaway 24-hour site and forces a separate claim. Before the three calls, resolve a key and decide ownership:

1. **Resolve a key, first match wins:** (1) `AGENTPUB_API_KEY` env var; (2) `~/.config/agentpub/credentials` (file mode `0600`).
2. **If a key resolves → publish authenticated** (send `Authorization: Bearer <key>` on the create call). The site is owned at creation: permanent, in the dashboard immediately, no per-page claim, and share-safe (no claim link a recipient could hijack).
3. **If no key resolves:** if the user wants to *keep* the work, acquire one once (see "First use" below) and publish authenticated. Only publish **anonymous** for a deliberate zero-signup throwaway/trial.
4. **Anonymous is an explicit choice, never a fallback.** Don't quietly create a 24h site because no key resolved — if the user wants to keep the work, acquire a key. Only go anonymous when the user explicitly asked for a throwaway. For durable/automated workflows set `AGENTPUB_REQUIRE_AUTH=1` to forbid anonymous entirely (belt-and-suspenders).

Shortcut: the bundled `agentpub.sh` encodes all of this. `./agentpub.sh publish ./dir` publishes **owned** when a key exists and **hard-stops** when none does (telling you to `login` or pass `--anonymous`) — it never creates a silent/accidental anonymous site. `--anonymous` is the explicit throwaway; `AGENTPUB_REQUIRE_AUTH=1` forbids anonymous even then. MCP-host agents (Claude, Cursor) can instead use the `agentpub.io/mcp` endpoint, where the host manages auth.

## The three calls

1. Create — declare each file with its **exact byte size**. Authenticated by default:

```bash
curl -sX POST https://agentpub.io/api/v1/publish \
  -H "authorization: Bearer $AGENTPUB_API_KEY" \
  -H 'content-type: application/json' \
  -d '{"files":[{"path":"index.html","size":1234,"contentType":"text/html"}]}'
```

Returns `upload.versionId`, `upload.uploads[]` (each `{path, method:"PUT", url}`), `upload.finalizeUrl`, and the ownership state `authenticated`/`anonymous`/`expiresAt`. **Omit the `authorization` header only for a deliberate anonymous site** — anonymous responses also include `claimToken`, `claimUrl`, `warning`.

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

## Confirm ownership after finalize (surface it loudly)

Every publish response carries the ownership state — **check it and report it to the user** so an accidental anonymous site is caught immediately:

```
authenticated: true
anonymous: false
expiresAt: null
```

If you see `authenticated: false` / `anonymous: true` / a non-null `expiresAt` when the user wanted to keep the site, you published the unsafe path — acquire a key and republish (or claim via the returned `claimUrl`).

## First use — acquire and persist a key once (no browser)

**Preferred for headless agents: device pairing.** Run `./agentpub.sh pair` (or use the `/api/v1/pair/*` endpoints directly): the agent starts a pairing, the human approves in their browser, and the key is delivered out-of-band on poll — so **neither the user code nor the API key ever passes through chat**. The `deviceSecret` stays with the agent and `agentpub.sh pair` persists the key to `~/.config/agentpub/credentials` (0600). For headless integration, run `agentpub.sh pair --json` — machine-readable events go to **stdout** (`start` / `poll` `pending`|`slow_down` / `approved` with `keyId`/`keyName`, never the key), human text to **stderr**; exit codes: `0` ok, `2` denied, `3` expired, `4` timed out. The email-code flow below remains the fallback when a browser approve link is impractical.

When no key resolves and the user wants to keep their work:

1. `POST /api/auth/agent/request-code` `{"email":"you@example.com"}` → a 6-digit code is emailed.
2. User reads the code back to you → `POST /api/auth/agent/verify-code` `{"email":"you@example.com","code":"482913"}` → returns `{"apiKey":"...","accountCreated":true|false}`.
3. **Persist** it so you never claim again:

```bash
mkdir -p ~/.config/agentpub && umask 177
printf '%s\n' "$APIKEY" > ~/.config/agentpub/credentials
chmod 600 ~/.config/agentpub/credentials
```

4. **Name the key for the tool holding it:** `POST /api/v1/keys` `{"name":"claude"}` (use `claude`, `cursor`, `hermes`, …) — each tool keeps its own revocable key on the one account (least privilege; revoke one without breaking the others).
5. **Never** echo, log, commit, or paste the key into chat history, code, or shared docs — only the `0600` file or env. Treat it like a password.

## Anonymous (only when explicitly intended)

- **No auth** → 24h site + a one-time `claimToken`/`claimUrl`. **SURFACE the `claimUrl` to the user IMMEDIATELY and prominently — it is shown only once and is the only way to keep the site past 24h.** Never log or paste the `claimToken` anywhere else.

## Updating

`PUT /api/v1/publish/{slug}` (same body shape as create). Authorize with the owner's `Bearer` header (or `{"claimToken":"..."}` in the body for an anonymous site). Include a per-file `hash` (sha256, lowercase hex — `shasum -a 256 file`) so files whose hash matches the live version skip upload (returned under `upload.carried`); only changed files get presigned URLs. Then finalize as above. Dedup only works when hashes were also sent on the version being compared against — send `hash` on every publish including the first.

## Quick reference

| Action         | Call                                                                                      |
| -------------- | ----------------------------------------------------------------------------------------- |
| Site status    | `GET /api/v1/sites/{slug}`                                                                |
| List my sites  | `GET /api/v1/sites` (Bearer)                                                              |
| Versions       | `GET /api/v1/publish/{slug}/versions` (Bearer or `?claimToken=`)                          |
| Rollback       | `POST /api/v1/publish/{slug}/rollback` `{"versionId":"..."}`                              |
| Delete         | `DELETE /api/v1/publish/{slug}` (Bearer, or `{"claimToken":"..."}`)                       |
| List keys      | `GET /api/v1/keys` (Bearer)                                                               |
| Mint named key | `POST /api/v1/keys` `{"name":"cursor"}` (Bearer)                                          |
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
