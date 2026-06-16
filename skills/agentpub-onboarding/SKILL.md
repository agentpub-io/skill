---
name: agentpub-onboarding
description: Use when a user first encounters agentpub or asks what it is / how to use it, or when you want to show (not tell) what agentpub does. Builds the user a personalized, reviewable artifact in ~2 minutes and walks them through the publish → review → revise → approve → keep loop — dogfooding the product itself.
metadata:
  author: agentpub
  version: "1.0"
---

# agentpub onboarding

The fastest way to explain agentpub is to **use it on the user**. Instead of
describing the product, build them something real — a page they can open, click,
comment on, and watch revise live — then offer to keep it. The whole loop runs
in about two minutes and composes only existing primitives: anonymous publish →
enable review → comment → live revise → claim.

This skill is the choreography. The artifacts come from the archetype templates
in `assets/` (plus the `client-status-report` blueprint, reused as a fourth).

## Opt-in (offer once, never force)

Offer onboarding **once**, in a single line, then respect the answer:

> "Want a 2-min personalized demo? I'll build you something you can actually use."

If they say yes, run the choreography. If they decline or ignore it, drop it and
continue the conversation normally — never re-pitch, never gate anything behind
it.

## Inference ladder (climb down only when you must)

Before asking anything, build the demo from the user's **real context**. Ask a
question only when you genuinely have nothing to work from. Work top-down:

1. **Their actual work** _(default — zero questions)_. Use this conversation, the
   files in front of you, and their past work to pick a real subject. This is
   almost always enough — use it.
2. **Role / persona.** If their work is unclear, infer their role from context;
   only if you still can't, ask one easy question: _"What kind of work do you
   do?"_
3. **Interest.** If role is genuinely unknowable, ask _"What's something you're
   into?"_ and build the demo around that.
4. **Cold-start default.** If you have nothing at all, build the `explainer`
   archetype about agentpub itself — it explains the product while demonstrating
   it.
   Make this cold-start demo genuinely impressive — strong design, real motion,
   a believable subject — so even the generic case sells what's possible.

Rule of thumb: **build from their real context first; climb down the ladder only
when you genuinely have nothing.** A demo about something they care about beats a
generic one every time.

## Persona → archetype mapping

| Persona / signal                      | Archetype              | Template                                       |
| ------------------------------------- | ---------------------- | ---------------------------------------------- |
| consultant / agency / client work     | `client-status-report` | `../client-status-report/assets/template.html` |
| marketer / growth / product launch    | `launch-onepager`      | `assets/launch-onepager.html`                  |
| founder / CEO / fundraising           | `investor-update`      | `assets/investor-update.html`                  |
| generic / interest-based / cold-start | `explainer`            | `assets/explainer.html`                        |

When in doubt, the `explainer` archetype is the safe default.

## The choreography

1. **Offer** the 2-minute demo (one line, above). Stop here if declined.
2. **Infer** the persona and a real subject using the inference ladder — prefer
   their actual context; ask at most one question.
3. **Pick** the archetype from the mapping table and a concrete subject drawn
   from their real work.
4. **Fill** the template: copy the locked `<style>` block **byte-identical**,
   replace only the section content with real, specific copy. Leave
   `{{CLAIM_URL}}` as a placeholder for now (see `assets/_furniture.md`).
5. **Publish anonymously** via the three-call flow (`agentpub-publish`): create
   (no auth) → PUT the HTML → finalize. Tag it for measurement (see below).
   Capture the `slug`, `claimToken`, and `claimUrl` from the create response.
6. **Fill `{{CLAIM_URL}}`** with the returned `claimUrl` and re-PUT + finalize so
   the live page's claim CTA points somewhere real.
7. **Enable review** with the `claimToken`: `POST /api/v1/publish/{slug}/review`
   `{"enabled":true,"claimToken":"<token>"}` (or the `enable_review` MCP tool).
8. **Share** the live `https://{slug}.agentpub.io/` URL.
9. **Invite the comment** explicitly, teaching the gesture by doing it: _"Open it,
   tap **Comment** (bottom bar), pick any line, type a note, then tell me."_
   Selecting an element is the path; the email field is optional (the owner can
   skip it). The bar also has **Share**, which copies the link so they can collect
   others' feedback.
10. **On a comment:** read it (`get_feedback` / GET `/comments`), revise the page
    live (update → re-PUT → finalize), then `mark_addressed` (with the
    `claimToken`) so `openComments` returns to 0.
11. **Offer the claim:** point them at the `claimUrl` to keep it past 24h, and
    offer to "make your real one" — fold the design into a permanent owned
    artifact or a blueprint.

## After the first demo: stop claiming, start owning

First touch stays anonymous — the personalized demo above is published with no
key so there's zero signup friction. But the moment the user wants to **keep**
their work, acquire and persist a key **once** (see `agentpub-publish` → "Key
lifecycle": `request-code` → `verify-code` → save to
`~/.config/agentpub/credentials`, mode `0600`), then publish authenticated
(`Bearer`) from then on. Owned sites are owned at creation — they appear in the
dashboard immediately with no per-page claim dance. Acquire once, reuse forever;
never run the claim flow page after page.

## Measurement tag (required)

Publish every onboarding demo with this artifact metadata so the funnel
(generated → commented → addressed → claimed) is measurable from the existing
server-side events:

```json
{
  "artifact": {
    "artifactType": "onboarding_demo",
    "sourceAgent": "onboarding-skill"
  }
}
```

These appear in the site's `.well-known/artifact.json`. Never omit them on an
onboarding demo — they are how onboarding is distinguished from ordinary
publishes.

## Guardrails: value-first, always

- **The revision happens regardless.** Reviewing and revising the page is free and
  unconditional — never require an account or signup to act on a comment.
- **Email is optional, never a gate.** The comment composer asks for the comment
  first; the email field below it is optional (provide it to be notified when the
  feedback is applied, or leave it blank to comment anonymously) and is remembered
  per device. The owner can simply skip it.
- **Claiming is "keep what you already have," never a toll.** The user experiences
  the full loop first; the claim step (via the "keep this page" line in the bar)
  only makes permanent something they can already see working.
