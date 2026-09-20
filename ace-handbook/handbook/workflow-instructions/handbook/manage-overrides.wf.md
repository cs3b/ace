---
doc-type: workflow
name: manage-overrides
title: Manage Project-Local Overrides
description: Canonical reference for ace-managed document override surfaces, resolution precedence, and verification probes
purpose: Documentation for ace-handbook/handbook/workflow-instructions/handbook/manage-overrides.wf.md
allowed-tools:
  - Bash(ace-nav:*)
  - Bash(ace-bundle:*)
  - Bash(ace-handbook:*)
  - Read
  - Write
  - Edit
ace-docs:
  last-updated: 2026-09-20
  last-checked: 2026-09-20
---

# Manage Project-Local Overrides

## Goal

Answer, from shipped documentation and tooling, the three override questions: which ace-managed documents can this
project override, where do the project-local files live, and who wins when a project-local file and a gem file share
the same name. This workflow is the canonical reference; `ace-nav resolve --why` makes the same precedence observable
per URI.

## Prerequisites

- Understanding of handbook asset conventions (workflows, cookbooks, guides, skills)
- `ace-nav` and `ace-handbook` available in the project bundle

## Override Surfaces

| Surface | Protocol | Project-local location | Overridable? | Winner of duplicates (shipped defaults) |
|---------|----------|------------------------|--------------|------------------------------------------|
| Workflows | `wfi://` | `.ace-handbook/workflow-instructions/<ns>/<name>.wf.md` | Yes | Project-local, when its source priority is lower than the gem source's (e.g. the shipped `local` source at priority 5 vs gem at 10) |
| Cookbooks | `cookbook://` | `.ace-handbook/cookbooks/<name>.cookbook.md` | Yes | The candidate from the source with the lower priority number. The shipped project-local default registers priority 20 and the gem source 10, so **the gem wins by default**; register a project cookbook source with priority < 10 to make project-local win |
| Guides | `guide://` | `handbook/guides/<name>.g.md` | Yes, with registration | Requires a project source registration (`.ace/nav/protocols/guide-sources/local.yml` → `handbook/guides`); with priority < 10 the project-local guide wins. Without registration the gem wins |
| Skills | `skill://` | none | **No** | Always the gem. Skills are thin layers; override the workflow the skill calls instead |
| `.agents/skills/` projection | — | written by `ace-handbook sync` | Never edit | Not a resolution source. Neutral `agents`-provider mirror regenerated (and stale entries pruned) on every sync; it does not ship |

## Resolution Rule

Sources for a protocol are scanned in ascending priority order (lower number = higher precedence); the first source
containing the resource wins and remaining duplicates are ignored. Registration defaults: project sources 10, user
sources 50, gem defaults 100 — an individual source registration may pin another value (this is why the shipped
`local` workflow source at priority 5 beats the gem at 10, while the shipped project-local cookbook source at 20 loses
to the gem at 10).

To answer "why did this candidate win?" for a concrete URI without planting probe files:

```bash
ace-nav resolve wfi://release/publish --why
# uri: wfi://release/publish
# rule: Candidates are tried in ascending source-priority order ...
# candidates (resolution order):
#   1. [priority 5]  @local (project) → ...   ← winner
#   2. [priority 10] @ace-handbook (gem-default) → ...
```

## Skills Are Not Overridable

Skills (`skill://`) are thin launch layers that load and execute a workflow; they carry no logic worth overriding.
Consequently no project-local skill source exists: competitors planted in `.ace-handbook/skills/` or `.agents/skills/`
are ignored and resolution always returns the gem file. The design rule is: **override the workflow the skill calls**
(under `.ace-handbook/workflow-instructions/`), not the skill. To change a skill's own wording, change the canonical
`handbook/skills/<name>/SKILL.md` in the owning gem and run `ace-handbook sync`.

## Process Steps

1. **Identify the surface** you need to override (workflow, cookbook, or guide) and its canonical gem path.
2. **Create the project-local file** at the surface's project-local location (see table), keeping the canonical
   frontmatter and structure so tools keep resolving it.
3. **Ensure the source registration makes your file win:**
   - workflows: keep `.ace/nav/protocols/wfi-sources/local.yml` priority below the gem source (shipped default: 5).
   - cookbooks: register `.ace/nav/protocols/cookbook-sources/local.yml` with priority < 10 (the shipped
     project-local default of 20 loses to the gem's 10).
   - guides: register `.ace/nav/protocols/guide-sources/local.yml` pointing at `handbook/guides` with priority < 10;
     without a registration the project-local file is never the winner.
4. **Verify precedence with `ace-nav resolve <uri> --why`:** your file must be listed first and marked
   `← winner`. For a list of all duplicate candidates use `ace-nav list '<protocol>://<name>'`.
5. **Never override skills or the `.agents/` projection.** Point the skill at an overridden workflow, or edit the
   canonical skill in its gem.
6. **Document the override** in the project's own agent guidance so maintainers know the file shadows a gem asset and
   should be re-checked on gem upgrades.

## Success Criteria

- [ ] Each project-local override file lives at the canonical project-local path for its surface.
- [ ] `ace-nav resolve <uri> --why` shows the project-local candidate first, marked `← winner` (or, for skills, shows
      the gem candidate only).
- [ ] No files were planted in `.ace-handbook/skills/` or `.agents/skills/` expecting resolution changes.
- [ ] `ace-handbook sync` runs clean after any canonical skill change.

## Validation Commands

```bash
ace-bundle wfi://handbook/manage-overrides
ace-nav resolve wfi://release/publish --why
ace-nav list 'cookbook://setup-starting-a-multi-ruby-gem-monorepo-with-ace'
ace-handbook sync
```

## Planted-Competitor Verification Probes

Executed against ace-handbook 0.31.1 / ace-support-nav 0.28.6 (2026-09-20). Plant a project-local competitor file,
run the resolve, inspect the first line of the winner, then remove the plant:

```bash
# Workflows: project-local WINS
mkdir -p .ace-handbook/workflow-instructions/handbook
printf '# OVERRIDE\n' > .ace-handbook/workflow-instructions/handbook/manage-cookbooks.wf.md
ace-nav resolve wfi://handbook/manage-cookbooks        # → .ace-handbook/... (project-local)
rm .ace-handbook/workflow-instructions/handbook/manage-cookbooks.wf.md

# Cookbooks: with shipped defaults the GEM wins (project-local source priority 20 > gem 10)
mkdir -p .ace-handbook/cookbooks
printf '# OVERRIDE\n' > .ace-handbook/cookbooks/setup-starting-a-multi-ruby-gem-monorepo-with-ace.cookbook.md
ace-nav resolve cookbook://setup-starting-a-multi-ruby-gem-monorepo-with-ace   # → ace-handbook/handbook/... (gem)
ace-nav list 'cookbook://setup-starting-a-multi-ruby-gem-monorepo-with-ace'    # both candidates listed
rm .ace-handbook/cookbooks/setup-starting-a-multi-ruby-gem-monorepo-with-ace.cookbook.md

# Skills: gem WINS even with competitors in both overlay locations
mkdir -p .ace-handbook/skills/as-review-pr .agents/skills/as-review-pr
printf '# OVERRIDE\n' > .ace-handbook/skills/as-review-pr/SKILL.md
printf '# OVERRIDE\n' > .agents/skills/as-review-pr/SKILL.md
ace-nav resolve skill://as-review-pr                   # → ace-review/handbook/skills/... (gem)
rm .ace-handbook/skills/as-review-pr/SKILL.md
rmdir .ace-handbook/skills/as-review-pr .ace-handbook/skills
ace-handbook sync                                      # regenerates .agents/skills/ and prunes the plant
```

## Error Handling

- **Override silently loses:** inspect `ace-nav resolve <uri> --why`; the losing candidate's source priority is too
  high — lower it in the source registration.
- **Guide override not discovered at all:** no project guide source is registered; add
  `.ace/nav/protocols/guide-sources/local.yml` (see Process Step 3).
- **Skill edit appears to do nothing:** skills are not overridable; override the workflow the skill calls.
- **`.agents/skills/` edits keep disappearing:** expected — `ace-handbook sync` regenerates the projection and prunes
  stale entries; edit canonical skills in the owning gem.
