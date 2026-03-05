---
title: Migrate and Standardize dev-handbook Content into ace-handbook Gem
filename_suggestion: chore-handbook-migration-cleanup
enhanced_at: 2026-01-03 20:33:42.000000000 +00:00
llm_model: gflash
status: done
completed_at: 2026-01-09 14:30:44.000000000 +00:00
id: 8o2utp
tags: []
created_at: '2026-01-03 20:32:59'
---

# Migrate and Standardize dev-handbook Content into ace-handbook Gem

## Problem
The project's AI integration assets (Workflows, Agents, Guides) are currently split between the legacy `dev-handbook/` directory and the planned `ace-handbook` gem. This redundancy violates the ACE vision of packaging capabilities as installable gems and increases maintenance complexity.

Recent modifications and updates made to workflows within `dev-handbook/` must be systematically reviewed and migrated to the new `ace-handbook` structure before the legacy directory can be deprecated.

## Solution
Finalize the creation of the `ace-handbook` gem, classifying it under the `ace-integration-*` pattern (asset packaging, no primary CLI). Systematically audit all recent changes in `dev-handbook/` and move the finalized, up-to-date content into the corresponding `handbook/` structure within the new gem.

This ensures that all guides, agents (`.ag.md`), and workflow instructions (`.wf.md`) are centralized and packaged for distribution, adhering to **ADR-001 Workflow Self-Containment**.

## Implementation Approach
1. **Gem Structure:** Implement `ace-handbook` following the `ace-integration-*` pattern defined in `docs/ace-gems.g.md`. This means including `handbook/` for workflows and ensuring the `.gemspec` includes all necessary assets.
2. **Migration Audit:** Use `ace-git diff` against the `dev-handbook/` path to identify all changes since the last major mono-repo cleanup commit (`d20756e3`). Apply these changes to the new `ace-handbook/handbook/` directory.
3. **Discovery Integration:** Register the `ace-handbook` workflows with `ace-nav` using the required `.ace-defaults/nav/protocols/wfi-sources/ace-handbook.yml` file, enabling `wfi://` discovery.
4. **Cleanup:** Once verified, update `docs/blueprint.md` and `docs/architecture.md` to reflect the deprecation of the `dev-handbook/` path, relying solely on the `ace-handbook` gem for shared AI assets.

## Considerations
- **ATOM Architecture:** Since this is an integration package, the focus is on the `handbook/` content structure rather than complex Atoms/Molecules, but the gem itself must follow the standard structure.
- **Path Updates:** Ensure all internal references, especially those in `.claude/` (symlinks to agents/workflows), are updated to point to the new `ace-handbook` location.
- **Dependency:** Ensure `ace-handbook.gemspec` correctly lists runtime dependencies, likely including `ace-core` and `ace-nav`.

## Benefits
- Fully realizes the project vision of making development capabilities installable via `gem install ace-handbook`.
- Eliminates the legacy `dev-handbook/` directory, simplifying the mono-repo structure.
- Provides a single, reliable source for standardized guides and workflows for autonomous agents.

---

## Original Idea

```
ace-handbook vs dev-handbook ->  btw we have check all the recent modifications for dev-handbook and move them to ace-handbook
```