---
id: 8wj.t.ocz
status: draft
priority: medium
created_at: "2026-09-20 16:15:48"
estimate: medium
dependencies: []
tags: [ace-overseer, workflow-instructions, nav, packaging]
needs_review: true
---

# Ship overseer lifecycle workflow so wfi://overseer resolves for gem consumers

Implements overseer task 8wf.t.r59 (cs3b/lab-overseer PR #10, merge `31a0382`,
task commit `1a1ee45`) on the ace side. This is the product-task spec for the
builder Work; it is not the implementation.

## Problem (evidence, executed 2026-09-20)

Installed gem `ace-overseer (0.15.5)`; source `cs3b/ace` `main` at `e48c8af13`
(clean, aligned with origin).

1. **Failing resolution (executed from a neutral env, no project-local nav
   registrations):**

   ```
   $ ace-bundle wfi://overseer
   Failed to resolve protocol: wfi://overseer
   $ ace-nav resolve wfi://overseer
   Resource not found: wfi://overseer   (rc=1)
   ```

   Same failure in the overseer project bundle env. The working precedent in
   the same env: `ace-nav resolve wfi://hitl` →
   `ace-hitl-0.8.9/handbook/workflow-instructions/hitl.wf.md` (rc=0) — bare
   protocols resolve to a top-level `<name>.wf.md` under a gem's
   `handbook/workflow-instructions/`.

2. **Root cause, established by executed inspection (supersedes the r59-era
   belief that the gem ships no workflow-instructions payload):**
   - The payload file already exists in source
     (`ace-overseer/handbook/workflow-instructions/overseer.wf.md`, since
     `a4e9a902c`, 2026-03-12) and inside the installed 0.15.5 gem (verified
     via `gem contents ace-overseer`); the gemspec globs `handbook/**/*`, so
     packaging is not the gap.
   - The consumer-side nav registration is what is missing: ace-nav discovers
     wfi sources for installed gems only through each gem's
     `.ace-defaults/nav/protocols/wfi-sources/*.yml`
     (`SourceRegistry#discover_gem_default_sources` scans installed `ace-*`
     gems). `ace-overseer/.ace-defaults/nav/protocols/` ships only
     `skill-sources/ace-overseer.yml` — no `wfi-sources/` entry. The working
     precedent `ace-hitl` ships
     `.ace-defaults/nav/protocols/wfi-sources/ace-hitl.yml`; that is why
     `wfi://hitl` resolves and `wfi://overseer` does not.
   - In the ace monorepo itself, a project-local
     `.ace/nav/protocols/wfi-sources/ace-overseer.yml` masks the defect
     in-repo (resolution succeeds from `/lab/projects/ace`), which is why the
     gap survived since March.

3. **The shipped payload is a thin stub.** Three one-line steps (run work-on,
   run status, run prune) with no lifecycle semantics and no executed-check
   contracts, while `ace-overseer/handbook/skills/as-overseer/SKILL.md`
   declares `skill.execution.workflow: wfi://overseer` and instructs "Load and
   run `ace-bundle wfi://overseer` … execute it end-to-end" — a dangling
   pointer into a stub.

4. **Incident pattern (per r59 Problem section).** With no binding process
   contract, overseer sessions degrade to improvised manual operation — the
   condition that produced the 2026-09-16 host-side incidents (prune
   recommended without an executed preservation proof; a stale owner-blocker
   accepted as state): the "described claim accepted instead of executed
   check" pattern. Interim mitigation lives host-side in
   `cs3b/omarchy-config` `.agents/skills/as-overseer/SKILL.md` (embedded
   operating contract: prune safety + status truth). The shipped workflow must
   preserve those guarantees so the interim text can later be slimmed back to
   a pointer (operator follow-up, out of scope here).

## Behavioral specification

Ship workflow instructions for the overseer lifecycle in the `ace-overseer`
gem so that `wfi://overseer` resolves for any consumer after gem install, and
the loaded content is the binding process contract:

1. Register the wfi source for gem consumers:
   `.ace-defaults/nav/protocols/wfi-sources/ace-overseer.yml` mirroring the
   proven `ace-hitl` registration (type gem, relative_path
   `handbook/workflow-instructions`, pattern `*.wf.md`, priority per
   convention).
2. Replace the stub `handbook/workflow-instructions/overseer.wf.md` with
   workflow instructions encoding at minimum the semantics of `work-on`,
   `status`, and `prune`, with these executed-check contracts as first-class,
   non-negotiable steps:
   - **Prune safety**: prune/removal of a worktree/branch only after an
     executed preservation proof — `git merge-base --is-ancestor
     <work-head> <base>`, or subject-level search in the successor repository
     for migrated work (e.g. `git -C <successor-repo> log --all --grep
     "<subject>"`). A described or remembered proof is never sufficient; any
     commit without a proven copy blocks the prune and is reported, never
     silently dropped.
   - **Status truth**: recorded blockers are claims, not state. Status
     reviews re-verify pending owner-blocked tasks with an executable
     non-secret check when one exists, and close or correct stale tasks in
     the same change instead of accepting a recorded blocker as state.

## Interface contract

```bash
ace-nav resolve wfi://overseer   # → <gem>/handbook/workflow-instructions/overseer.wf.md
ace-bundle wfi://overseer        # loads the workflow, not "Failed to resolve"
```

Valid from a consumer environment with no project-local nav registrations,
after gem install/update.

## Acceptance criteria

- [ ] On a fresh session after gem update, `ace-bundle wfi://overseer` loads
      the workflow (not "Failed to resolve").
- [ ] The loaded workflow contains the prune-safety and status-truth
      executed-check steps as first-class steps.
- [ ] The gem ships `.ace-defaults/nav/protocols/wfi-sources/ace-overseer.yml`
      (ace-hitl pattern); `ace-nav resolve wfi://overseer` resolves from a
      clean consumer env with no project-local registration.
- [ ] The gem version is bumped; the version bump is the delivery signal
      (publication is a separate privileged release Work) and release notes
      state the new protocol availability.
- [ ] Gem test suites green.
- [ ] A packaging check proves the workflow-instructions file ships inside the
      built gem (verify the gemspec file globs actually include it — today
      `handbook/**/*` — with an assertion or test so a future glob change
      cannot silently drop the payload).

## Verification plan

- Resolve/bundle probes from a clean bundle env (`env -u GEM_HOME -u GEM_PATH`,
  no project-local `.ace/nav` wfi registrations, mise-managed gem install)
  against the built/installed gem; same probes must keep passing from the ace
  monorepo checkout (project-local registration coexists).
- Gemspec packaging assertion or equivalent test (built-gem contents include
  `handbook/workflow-instructions/overseer.wf.md` and
  `.ace-defaults/nav/protocols/wfi-sources/ace-overseer.yml`).
- Handbook contract/lint checks per repo conventions.
- Content review against this spec's behavioral specification: work-on,
  status, and prune semantics present; both executed-check contracts explicit.

## Out of scope

- Changing ace-bundle protocol resolution itself (other gems already resolve;
  this gem lacks its registration and real payload).
- Any omarchy-config or Lab control-plane changes, including slimming the
  interim contract (operator follow-up after local verification).
- RubyGems publication itself (separate privileged release Work).
- Overseer repository changes (cs3b/lab-overseer).

## Provenance

- Overseer task `8wf.t.r59` "Ship ace-overseer skill/workflow so wfi://overseer
  resolves" (cs3b/lab-overseer PR #10, merge `31a0382`, task commit `1a1ee45`)
  — reviewed authority for the target state.
- selfimprove session 2026-09-16 (overseer executed checkpoints; incident 3 of 3).
- Interim contract: `cs3b/omarchy-config` `.agents/skills/as-overseer/SKILL.md`.
- Resolution-convention evidence (executed 2026-09-20): `wfi://hitl` resolves
  to a top-level workflow file; `wfi://retro` (namespace without a name) does
  not (`wfi://retro/selfimprove` does, rc=0); monorepo-local `wfi://overseer`
  resolves via project-local source registration while consumers fail — the
  masking effect documented above.

