---
id: 8wj.t.vle
status: pending
priority: low
created_at: "2026-09-20 21:03:46"
estimate: 
dependencies: []
tags: [handbook, nav, overrides, polish]
---
# Clarify guide-override discovery wording and the priority-5 source phrasing in manage-overrides

Follow-up to 8wg.t.tjv (delivered via W669/PR #24): the independent
review approved with two non-blocking wording findings (N1/N2). This
task lands the wording corrections only — no behavior change.

## Behavioral Specification

### User Experience

- **Input:** a reader of `wfi://handbook/manage-overrides` asks (N1)
  "is a planted guide override discovered at all?" and (N2) "do I
  already have a priority-5 local wfi source downstream?".
- **Process:** documentation wording only.
- **Output:** both questions answered unambiguously from the page.

### Expected Behavior (from the PR #24 review, verified findings)

1. **N1 — Error Handling section**: replace "Guide override not
   discovered at all: no project guide source is registered." with
   wording that reflects executed behavior: ace-support-nav ships a
   gem-default example directory source (`@ace-support-nav` →
   `./handbook/guides`, priority 100) that auto-loads in every project,
   so a planted guide IS discovered as a losing candidate (verified
   live: position 2, priority 100). Suggested: "discovered but loses
   (gem-default example source at priority 100) or not discovered,
   depending on registration; the remedy — register
   `guide-sources/local.yml` with priority < 10 — is correct under both
   readings."
2. **N2 — table/Process-Step phrasing**: "(shipped default: 5)" /
   "the shipped local source at priority 5" refers to THIS monorepo's
   own checked-in `.ace/nav/protocols/wfi-sources/local.yml`; no gem
   default or scaffolding creates a project-local wfi source for
   downstream consumers. Reword so a downstream reader cannot infer
   they already have a priority-5 source (keep the operative rule:
   keep priority below the gem source).

### Interface Contract

Docs-only: `ace-handbook` workflow page content. No gem behavior,
CLI, or test semantics change. Handbook lint/contract checks stay
green.

### Verification plan

- The two sections read unambiguously per above; grep the old phrases
  → gone.
- Planted-guide probe re-cited in the PR body (position/priority
  evidence for the losing-candidate claim).
- `ace-test ace-handbook all` green.

### Acceptance criteria

- [ ] N1 and N2 wording landed; old ambiguous phrases removed.
- [ ] Probes cited; handbook suite green.

## Provenance

Review report of PR #24 (`/lab/state/admin/reviews/W669/…report.md`,
findings N1/N2); task 8wg.t.tjv (done, W669).

### Review note (2026-09-20, promotion)

Fresh-eyes: scope is the two executed review findings verbatim; docs-only;
verification re-cites the probe. No blocking questions.
