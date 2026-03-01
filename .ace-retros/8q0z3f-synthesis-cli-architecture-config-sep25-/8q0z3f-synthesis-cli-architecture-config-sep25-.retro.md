---
id: 8q0z3f
title: "Synthesis: CLI, Tool Architecture, and Configuration (Sep 2025 – Jan 2026)"
type: standard
tags: [synthesis]
created_at: "2026-03-01 23:23:49"
status: active
---

# Synthesis: CLI, Tool Architecture, and Configuration (Sep 2025 – Jan 2026)

**Scope**: 45 retros covering CLI standardization, dry-cli/Thor migration, config hardcoding, env cascade, ace-config migration, hardcoded paths, ace-nav resolution, ace-docs/lint config, unified filters, and preset composition.
**Date range**: 2025-09-24 through 2026-01-07

## What Went Well

- **Systematic debugging and investigation approach** (Identified in 35/45 retros): Teams consistently applied structured problem identification — tracing from symptoms to root causes using grep, targeted file reads, and incremental testing.

- **Following ATOM architecture and established patterns** (Identified in 28/45 retros): Clean separation of concerns using the ATOM (Atoms/Molecules/Organisms) pattern made code easy to test, maintain, and extend. When existing patterns from other ace-* gems were followed, implementations were significantly smoother.

- **Test-driven development and immediate validation** (Identified in 30/45 retros): Running tests after each change caught issues early. Test-driven approaches prevented deployment of broken code in many cases.

- **Leveraging ace-core and shared infrastructure** (Identified in 18/45 retros): Centralizing common functionality (env loading, config cascade, CLI base classes) in ace-core/ace-support-core eliminated duplication and ensured consistency across gems.

- **Configuration-driven design** (Identified in 15/45 retros): Moving from hardcoded values to configuration-driven approaches improved flexibility and maintainability. The `.ace/` config cascade pattern proved powerful across multiple gems.

- **User feedback integration** (Identified in 20/45 retros): Fast feedback loops with user corrections drove better architectural decisions. User insights frequently redirected implementations toward simpler, more correct approaches.

## What Could Be Improved

- **Hardcoded paths and values scattered across codebase** (Identified in 18/45 retros): Repeatedly, hardcoded directory names ("t/", "retro/", "retros/"), configuration paths, timeouts, and limits caused bugs requiring systematic remediation. Configuration existed but was not consistently used in all code paths.

- **Insufficient integration/end-to-end testing** (Identified in 22/45 retros): Unit tests passing while features were broken was a recurring anti-pattern. CLI code paths, preset systems, glob patterns, and merge functions all had cases where unit tests gave false confidence while actual user-facing behavior was broken.

- **Incorrect initial assumptions requiring multiple iterations** (Identified in 25/45 retros): Agents frequently started with wrong assumptions about configuration format, directory structure, API patterns, or architecture, requiring user corrections and rework. Not researching existing patterns was the most common root cause.

- **Multiple code paths not all exercised** (Identified in 14/45 retros): ace-context had three entry points (load_auto, load_preset, load_multiple_inputs), and bugs in one path were masked by tests exercising another. Recurred across tools with CLI vs Ruby API entry points.

- **Incomplete migrations and cleanup** (Identified in 12/45 retros): Migration tasks focused on creating new artifacts but failed to clean up old ones, leaving duplicate commands, stale directories, and inconsistent states.

- **Over-engineering** (Identified in 10/45 retros): Complex solutions when simple ones existed, reimplementing internal logic instead of calling existing tools, or adding unnecessary layers of abstraction.

- **Documentation drift from implementation** (Identified in 12/45 retros): API documentation, example configs, README files, and help text frequently fell out of sync with actual implementations, especially after API changes.

## Key Learnings

- **Always research existing patterns before implementing** (from 20 retros): The single most impactful learning. Checking how other ace-* gems handle similar functionality before writing code prevents rework. Pattern: "Research > Plan > Implement" not "Implement > Discover > Rework."

- **Unit tests passing does not mean the feature works** (from 15 retros): Integration tests exercising actual CLI commands, real file structures, and end-to-end pipelines are essential. Tests mocking internal components provide false confidence.

- **Configuration exists but must be used everywhere** (from 12 retros): Having a configuration system is insufficient. Every code path must actually read from it. Audit all references after creating config systems.

- **Understand all code paths before modifying shared functions** (from 10 retros): When changing shared functions, trace ALL callers. ace-context's three entry points, Thor's option consumption behavior, and merge_contexts bugs all stemmed from incomplete code path analysis.

- **Backward compatibility requires explicit verification** (from 10 retros): When adding new features to existing code paths, always verify original behavior is preserved with regression tests.

- **Tool outputs should be trusted and used as designed** (from 8 retros): ace-* tools produce concise output with file paths for details. Over-complicating with shell manipulation wastes time and introduces errors.

- **Git worktree behavior is surprising** (from 4 retros): `git worktree add -b branch` uses main worktree HEAD, not current directory's branch. Auto-commit behavior on worktree creation caused data integrity issues.

- **CLI framework choice matters** (from 3 retros): Thor's option parsing conflicts with command delegation patterns. dry-cli better matches the ace-* Command pattern. Establishing conventions before the second implementation prevents expensive retrofits.

## Action Items

- **Add compliance audit subtask to all migration tasks** (from 15 retros): Every migration should include a final "audit compliance" step verifying all code paths use the new pattern, old artifacts are cleaned up, and documentation is updated.

- **Create integration test suites for CLI and preset systems** (from 18 retros): Add tests exercising actual CLI commands with real file structures. Test all entry points. Do not rely solely on unit tests for user-facing features.

- **Implement automated hardcoded path/value detection** (from 12 retros): Create a lint rule flagging string literals matching configured directory names, timeouts, or paths. Verify `.ace-defaults/` files are actually loaded.

- **Establish "Research Existing Patterns" as mandatory workflow step** (from 20 retros): Before implementing cross-cutting concerns, require examining at least 2 existing ace-* gems for established patterns.

- **Fix ace-git-worktree branch source bug** (from 3 retros): Add explicit start-point to worktree creation. Default to current branch. Add `--source` flag for explicit control.

- **Create API change checklist workflow** (from 8 retros): When changing an API: update primary README, update workflow instructions, update example configurations, regenerate cached context, and add migration guide.

- **Document CLI conventions in ADR and create generator** (from 5 retros): Formalize CLI standards in an Architecture Decision Record. Create template/generator for new CLIs.

## Additional Context

**Source retro IDs** (45 total):
8kn000, 8ko000, 8ks000 (×3), 8kt000 (×2), 8kp000 (×2), 8l1000, 8l4000, 8l6000 (×3), 8lc000 (×6), 8ld000, 8lf000, 8lg000, 8lh000, 8ln000 (×2), 8m0000 (×3), 8m3000, 8m4000, 8mb000, 8mr000 (×2), 8ml000, 8n2000, 8nf000 (×3), 8o0000, 8o2000 (×2), 8o4000, 8o5000, 8o6000

**Dominant theme**: The retros span work across 15+ ace-* gems. The most pervasive anti-pattern was hardcoded values persisting despite configuration systems existing. The most valuable learning was "research existing patterns before implementing" — sessions that followed this approach had dramatically fewer iterations and corrections.
