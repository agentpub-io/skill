---
name: agentpub-blueprints
description: Use when producing a consistent, on-brand, reusable artifact or deliverable with agentpub, when asked to create or use a blueprint, or when a user says "save this as a template" after liking a one-off output.
metadata:
  author: agentpub
  version: "1.0"
---

# agentpub blueprints

A **blueprint** is a skill that bundles three things so any agent can produce identical-looking artifacts without rebuilding HTML from scratch:

1. **Locked design tokens** — CSS custom properties declared once; a hard rule says never improvise colors or fonts.
2. **A fixed section structure** — the contract that every instance of this artifact type must satisfy.
3. **A reference template** — `assets/template.html` inside the skill directory, ready to copy-and-fill.

Purpose: consistent, branded, repeatable deliverables instead of drifting HTML each time.

## What the anti-drift rule means

**Do not improvise colors.** If a blueprint defines `--accent: #0f6b6b`, every instance uses `#0f6b6b` — not "a teal-ish color". The `<style>` block in `assets/template.html` must reach the published page BYTE-IDENTICAL (whitespace and all). Only the _content_ inside sections changes between instances. Drift accumulates fast when HTML is written free-hand; the template is the fix.

## Using a blueprint

1. Load the target blueprint skill (e.g. `client-status-report`).
2. **Copy** `assets/template.html` to a working file — never edit the asset in place for a one-off.
3. **Fill each section** from the user's inputs, replacing sample content. Keep the section order.
4. **Leave the `<style>` block and tokens unchanged.** Do not add new colors, swap fonts, or inline one-off hex values.
5. **Keep it self-contained:** inline `<style>` only; no `<link>`, no CDN scripts, no remote images or fonts. Renders anywhere, CSP-safe when published.
6. **Publish** via the `agentpub-publish` skill:
   - _Anonymous 24h draft_ — no auth; you receive a one-time `claimUrl`. **Surface it to the user immediately** — it is the only way to keep the site past 24h.
   - _Permanent owned deliverable_ — `Authorization: Bearer $AGENTPUB_API_KEY`.
7. Surface the live `https://{slug}.agentpub.io/` URL (and the `claimUrl` when anonymous).

See `skills/agentpub-publish/SKILL.md` for the exact three-call flow (create → upload → finalize).

## Creating a new blueprint

When a user has a reusable artifact type that doesn't exist yet:

1. **Design it once** — clean, professional, self-contained. No external resources. Print-friendly (include a print stylesheet so PDF export works). Aim for a restrained palette: one background, one surface, one ink, one accent, severity helpers if needed.
2. **Extract locked tokens** — lift every color, font stack, and spacing value into CSS custom properties. Write the "do not improvise" rule into the skill explicitly.
3. **Define the section contract** — a table of sections (Required / Optional) with brief notes on what each must contain.
4. **Save as a skill** — `skills/<artifact-type>/SKILL.md` + `skills/<artifact-type>/assets/template.html`.

Use `client-status-report` as the canonical worked example — its token table, section contract, and template structure are the reference pattern.

## "Save this as a template"

When a user likes a one-off artifact, offer to fold its design into a blueprint:

- If a matching blueprint already exists, reconcile the palette/structure into that skill's tokens and `assets/template.html`. One-offs compound into the blueprint rather than being lost.
- If no blueprint exists yet, create a new one (see above).
- Optionally publish the template itself as a permanent agentpub site for a visual reference — `Authorization: Bearer $AGENTPUB_API_KEY`, permanent ownership.

## Evolving (compounding)

To change the brand across all future artifacts of a type, edit the tokens and `assets/template.html` in the skill **once**. Every instance built from that template inherits the change automatically. Never fork the design per artifact.

## Self-describing artifacts (forward note)

Published artifacts can carry a `.well-known/artifact.json` manifest alongside `index.html`:

```json
{
  "artifactType": "client-status-report",
  "isTemplate": false,
  "designSystem": "agentpub-blueprint-v1",
  "status": "draft"
}
```

This lets other agents recognize artifact type, distinguish templates from instances, and locate the design system — enabling automated reuse without human-readable parsing.

## Companion skills

| Skill                  | Role                                                                        |
| ---------------------- | --------------------------------------------------------------------------- |
| `client-status-report` | Canonical blueprint worked example — token table, contract, template.       |
| `agentpub-publish`     | The publish step for every blueprint instance (create → upload → finalize). |
