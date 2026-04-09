# ace-assign README Review Summary

## ace-assign specific changes

### Content rewrites
1. **Tagline**: "Phase-based assignment queues" → "Multi-step assignment execution with nesting, fork delegation, and inspectable traces"
2. **Intro paragraph**: Rewrote to describe step catalog, presets, workflow instruction references, restartability. Added ace-overseer as easiest onboarding path.
3. **How It Works**: Rewrote 3 steps to reflect actual flow (define from preset/catalog → expand into session → drive with fork delegation)
4. **Use Cases**: Removed "concurrent assignments", added "Define assignments from presets" and "Run with orchestrator and fork agents" (sequential/parallel, inspectable traces)
5. **Status output example**: Added real `ace-assign status` output showing nesting, forks, failures
6. **Gemspec**: Updated summary/description to match new README terminology

### Terminology fix
7. **"phases" → "steps"** in `docs/handbook.md` (2 lines), `docs/getting-started.md` (2 lines), e2e fixture directories renamed `phases/` → `steps/`

### Broken links
8. **`docs/exit-codes.md`** "See Also" links pointed to non-existent README anchors (`#cli-commands`, `#error-handling`) → fixed to `usage.md` and `getting-started.md`

### Example links
9. Added inline links to concrete files: `work-on-task.step.yml`, `composition-rules.yml`, `work-on-task` preset

---

## Checklist for reviewing other packages

Based on what we found in ace-assign, here's what to check in each package:

| Check | What to look for |
|-------|-----------------|
| **Stale terminology** | grep for renamed concepts (e.g., "phases" after a rename to "steps") in docs/, handbook/, test-e2e/scenarios/ |
| **Gemspec matches README** | `spec.summary` and `spec.description` should match the current tagline, not an old one |
| **Broken doc cross-links** | `docs/*.md` "See Also" sections often link to README anchors that no longer exist after rewrites |
| **Undocumented executables** | Compare `ls exe/` against what the README mentions (we found `ace-review-feedback` and `ace-test-e2e-sh` missing) |
| **False feature claims** | Check protocol/flag/command claims against actual implementation (we found `task://` listed as built-in when it's extensible) |
| **Self-referential links** | Package linking to itself instead of the target (ace-support-nav linked `../ace-support-nav`) |
| **Dead anchor links** | `[Documentation](#documentation)` with no `## Documentation` heading (8 support packages had this) |
| **Jargon without definition** | First-time user terms: b36ts, frontmatter, scope-based splitting, ContextPack/3, @project/@user/@gem |
| **Platform constraints** | macOS-only packages should say so upfront (ace-support-mac-clipboard) |
| **Status output example** | ace-assign's real status output was very effective for showing what the tool does -- other CLI-heavy packages could benefit |
