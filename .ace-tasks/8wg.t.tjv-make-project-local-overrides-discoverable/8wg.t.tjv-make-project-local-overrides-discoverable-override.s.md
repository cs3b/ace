---
id: 8wg.t.tjv
status: draft
priority: medium
created_at: "2026-09-17 19:42:05"
estimate: TBD
dependencies: []
tags: [handbook, nav, overrides]
---

# Make project-local overrides discoverable: override surfaces, resolution precedence, and ace-nav ergonomics

## Behavioral Specification (draft)

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

### Expected Behavior (proposed)

1. `ace-handbook` ships a canonical override-management surface (extend `wfi://handbook/manage-cookbooks` or add `wfi://handbook/manage-overrides`) covering ALL surfaces: workflows, cookbooks, guides, skills (not overridable — thin layers; override the called workflow), `.agents/` projection status, with the precedence table and verification commands.
2. `ace-nav` exposes precedence: `list` duplicate entries indicate the winner (or a `--why` mode on `resolve` printing all candidates + the resolution rule).
3. Optional: `ace-nav create wfi://ns/name --override` scaffolds the project-local copy from the current gem content with a provenance header (source gem version), so overrides start from reality and divergence is visible.

### Interface Contract (draft)

```bash
ace-nav overrides                    # per surface: overridable? path? who wins?
ace-nav resolve --why wfi://x/y     # all candidates + the rule that picked one
ace-bundle wfi://handbook/manage-overrides   # canonical documentation
```

### Provenance

- Downstream reference implementation: cs3b/lab-config `cookbook://override-ace-docs` (PR #26, 3 review rounds) + AGENTS.md summary; full evidence transcript available.
- Related: task 8tt.t.stj (agents-provider projection), `ace-nav sources` directory-source registration (`.ace/nav/protocols/*-sources/project-local.yml`).
