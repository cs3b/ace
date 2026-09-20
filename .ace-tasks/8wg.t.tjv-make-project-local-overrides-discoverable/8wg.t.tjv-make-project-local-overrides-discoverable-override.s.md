---
id: 8wg.t.tjv
status: done
priority: medium
created_at: "2026-09-17 19:42:05"
estimate: medium
dependencies: []
tags: [handbook, nav, overrides]
needs_review: false
---

# Make project-local overrides discoverable: override surfaces, resolution precedence, and ace-nav ergonomics

## Behavioral Specification

### User Experience

- **Input:** A project maintainer or agent asks "which ace-managed documents can this project override, where do they live, and who wins when names collide?" — today this requires reading gem internals and planting probe files.
- **Process:** ACE answers from shipped documentation and tooling: a canonical handbook page states the override surfaces and the resolution rules; `ace-nav` reports precedence explicitly instead of silently picking a winner among `list` duplicates.
- **Output:** The answer is discoverable in one place per project and in `ace-nav` output; skills' non-overridability is documented as a design rule ("override the workflow the skill calls"), not rediscovered by failure.

### Problem (evidence, executed 2026-09-17; ace-handbook 0.31.0, ace-review 0.54.0)

1. Project-local files WIN `ace-nav resolve` for workflows (`.ace-handbook/workflow-instructions/ns/name.wf.md`), cookbooks (`.ace-handbook/cookbooks/`), guides (`handbook/guides/`) — verified by planted competitor files.
2. Skills are NOT overridable: `skill://as-review-pr` resolves to the gem even with a competitor planted in BOTH `.ace-handbook/skills/` and `.agents/skills/`.
3. `.agents/skills/` is the neutral `agents`-provider projection written by `ace-handbook sync` (task 8tt.t.stj / GH issue #306) — a local mirror that does not ship.
4. Nothing in any gem documents 1–3 together; downstream we had to author a project-local cookbook (`cookbook://override-ace-docs` in cs3b/lab-config) to make it obvious, following the canonical `wfi://handbook/manage-cookbooks` model.

The sharpest edge: a workflow override silently WINS while a skill override silently LOSES. "Customize the skill" is the intuitive first move and it does nothing.

### Expected Behavior

1. `ace-handbook` ships a canonical override-management surface (extend `wfi://handbook/manage-cookbooks` or add `wfi://handbook/manage-overrides`) covering ALL surfaces: workflows, cookbooks, guides, skills (not overridable — thin layers; override the called workflow), `.agents/` projection status, with the precedence table and verification commands.
2. `ace-nav` exposes precedence: `list` duplicate entries indicate the winner (or a `--why` mode on `resolve` printing all candidates + the resolution rule).

### Out of scope (follow-up candidate, not this task)

- `ace-nav create wfi://ns/name --override` scaffolding with provenance header (original EB item 3). Recorded as an idea; a separate task may adopt it after the documentation surface lands.

### Interface Contract

```bash
ace-nav overrides                    # per surface: overridable? path? who wins?
ace-nav resolve --why wfi://x/y     # all candidates + the rule that picked one
ace-bundle wfi://handbook/manage-overrides   # canonical documentation
```

Exact surface (new handbook page vs extending manage-cookbooks; `--why` vs annotated `list`) is an implementer decision guided by gem conventions; the contract is that BOTH questions — "which surfaces can I override?" and "why did this candidate win?" — are answerable from shipped tooling without planting probe files.

### Acceptance criteria

- [x] Canonical override documentation ships in `ace-handbook` and covers workflows, cookbooks, guides, skills (non-overridable, with the "override the called workflow" rule), and the `.agents/` projection status, with the precedence table and planted-competitor verification commands.
- [x] `ace-nav` answers precedence for duplicate candidates (winner indicated in `list` or `--why` on `resolve`), with tests covering the duplicate-candidate path.
- [x] Gem test suites green; documentation claims verified against actual resolution behavior (no asserted-but-unexecuted claims).

### Verification plan

- Planted-competitor probes per surface (the Problem section's method) against the shipped gems, executed and cited in the PR body.
- `ace-nav` unit tests for duplicate candidates (project-local wins workflows/cookbooks/guides; skills always resolve to the gem).
- Handbook contract/lint checks per gem conventions.

### Provenance

- Downstream reference implementation: cs3b/lab-config `cookbook://override-ace-docs` (PR #26, 3 review rounds) + AGENTS.md summary; full evidence transcript available.
- Related: task 8tt.t.stj (agents-provider projection), `ace-nav sources` directory-source registration (`.ace/nav/protocols/*-sources/project-local.yml`).

### Review note (2026-09-20, promotion)

Reviewed fresh-eyes: evidence is executed and reproducible; Expected Behavior items 1–2 are the bounded scope; EB item 3 (scaffolding) moved to out-of-scope; acceptance criteria and verification plan added; interface contract marked implementer-flexible on surface choice. No blocking questions.

### Delivery (2026-09-20)

Work W669 (golden path): PR #24 cs3b/ace, head 0ff9dd7290282152d36f08207b5b233ebb6874ec,
FF-merged (main tip == reviewed head). Independent adversarial review
(lab-admin, pi-deep): APPROVE, zero blocking findings, all probes re-executed
(report /lab/state/admin/reviews/W669/pr-24-1789908595283598530.report.md).
Suites: ace-support-nav 151/0, ace-handbook 49/0, monorepo 8915/0.
Notable correction over the draft spec: with shipped defaults the GEM wins
cookbook duplicates (priority 10 vs project-local 20) — documented per
actual behavior (docs must state the priority rule, not a fixed winner).
