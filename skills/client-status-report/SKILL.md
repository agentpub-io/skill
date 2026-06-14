---
name: client-status-report
description: Use when asked to build, generate, or produce a client status report — a period update for a client covering progress, risks, decisions, and next actions — to share or publish, especially via agentpub. This skill is a reusable on-brand blueprint so every report comes out consistent instead of being rebuilt from scratch.
metadata:
  author: agentpub
  version: "1.0"
---

# Client Status Report (blueprint)

This skill is a **blueprint**: a reusable, on-brand artifact design. Build a report by copying `assets/template.html` and filling it in — do NOT hand-write HTML from scratch each time, which drifts (random colors, inconsistent layout). The template and the tokens below ARE the design contract.

## Locked design tokens (anti-drift)

**Do not improvise colors.** Use these tokens exactly. They live as CSS custom properties at the top of `assets/template.html`; never replace a token value with a one-off hex inline. The palette is a restrained agency deliverable — warm-neutral paper, near-black ink, one slate-teal accent. High-contrast, WCAG AA. No purple/violet AI gradients.

### Palette

| Token           | Value     | Use                            |
| --------------- | --------- | ------------------------------ |
| `--ink`         | `#1a1d1f` | Primary text, top rule         |
| `--ink-soft`    | `#4a5054` | Secondary / body copy          |
| `--ink-faint`   | `#8b9296` | Meta, captions                 |
| `--paper`       | `#f7f5f1` | Page background                |
| `--surface`     | `#ffffff` | Cards                          |
| `--line`        | `#e3ded6` | Hairlines / borders            |
| `--accent`      | `#0f6b6b` | The one accent (slate-teal)    |
| `--accent-deep` | `#0a4f4f` | Accent strong                  |
| `--accent-wash` | `#e7f0ef` | Accent tint fills              |
| `--sev-high`    | `#a8341f` | Risk severity: high (+ wash)   |
| `--sev-med`     | `#9a6b14` | Risk severity: medium (+ wash) |
| `--sev-low`     | `#0f6b6b` | Risk severity: low (+ wash)    |

### Typography (system / web-safe only — no external fonts)

- `--font-display`: Iowan Old Style / Palatino / Georgia serif stack — masthead, section titles.
- `--font-body`: -apple-system / Segoe UI / Roboto sans stack — body copy.
- `--font-mono`: SF Mono / Menlo / Consolas — eyebrows, labels, severity pills.

### Spacing & shape

4px scale: `--s-1` (4) → `--s-9` (96). Radius `--radius` 10px, `--radius-sm` 6px. One elevation `--shadow`.

## Report structure (the contract)

Fill every required section. Optional sections may be dropped if there is genuinely nothing to report.

| Section              | Required? | Notes                                                                                              |
| -------------------- | --------- | -------------------------------------------------------------------------------------------------- |
| Header               | Required  | Report title + client name + reporting period + prepared-by + date issued. (Status chip optional.) |
| Executive summary    | Required  | 2–4 sentences: overall state, headline wins, what you need.                                        |
| Progress this period | Required  | 2–5 concrete items shipped/advanced this period.                                                   |
| Risks                | Required  | Each risk MUST have an **owner** and a **severity** (High / Medium / Low).                         |
| Decisions needed     | Required  | Decisions the client must make; include a by-when if known. Use "None this period" if empty.       |
| Next actions         | Required  | Owner + due date per action.                                                                       |

## How to build a new report

1. **Copy** `assets/template.html` to your working file (do not edit the asset in place for a one-off report).
2. **Fill each section** from the user's inputs, replacing the sample "Acme Co" content. Keep the section order and structure.
3. **Keep the design tokens unchanged.** Do not add new colors or swap fonts. If a risk is Low severity, reuse the `.severity.low` class — don't invent a style.
4. **Stay self-contained:** inline `<style>` only, the system/web-safe font stacks already in the template, and **no external resources** (no `<link>`, no CDN scripts, no remote images/fonts). This keeps it CSP-safe when published and makes it render anywhere.
5. **Print-friendly:** the template ships a print stylesheet for clean PDF export (white background, page margins, break-inside avoid). Leave it intact.

## Publish step

Publish via the `agentpub-publish` skill (create → upload → finalize):

- **Review draft → anonymous (24h).** Publish with no auth; you get a one-time `claimUrl`. **Surface that claim URL to the user immediately** — it is the only way to keep the site past 24h. Optionally enable review mode so the client leaves inline comments/approval, then apply feedback per the publish skill.
- **Permanent deliverable → owned.** Publish with `Authorization: Bearer $AGENTPUB_API_KEY` for an account-owned, permanent site.

Either way, surface the live `https://{slug}.agentpub.io/` URL (and the claim/review URL when anonymous) back to the user. See `skills/agentpub-publish/SKILL.md` for the exact calls.

## Compounding note

This skill IS the reusable blueprint. To improve every future report at once, edit the tokens and `assets/template.html` here — all reports built from it inherit the change. Don't fork the design per report.

## Save-as-template note

When a user likes a one-off report's design, fold it back in: lift its palette/type/spacing into the tokens above and reconcile `assets/template.html` to match. That way a good one-off compounds into the blueprint instead of being lost.
