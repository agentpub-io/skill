# Shared onboarding furniture

Every onboarding archetype embeds these three elements so the demo teaches and
converts even with zero agent hand-holding. Each element is adapted to its
template's token classes, but the copy is verbatim across archetypes. This block
appears near the top of the body (built-with line + review prompt) and at the
bottom (claim CTA).

```html
<!-- top: built-with framing -->
<p class="apb-meta">Built with <strong>agentpub</strong> in ~30 seconds — and you can review it right now.</p>

<!-- review prompt (self-guided backstop for the agent-guided loop) -->
<p class="apb-prompt">👈 Try it: click any element on this page and leave a comment. Your agent will see it and revise this live.</p>

<!-- bottom: claim CTA -->
<footer class="apb-claim">This preview disappears in 24 hours. <a href="{{CLAIM_URL}}">Keep it &amp; make it yours →</a></footer>
```

`{{CLAIM_URL}}` is the only placeholder. The agent fills it with the publish
response's `claimUrl` (returned once on an anonymous create) before the final
PUT/finalize. Everything else in the template is real content the agent fills
from the user's actual context.
