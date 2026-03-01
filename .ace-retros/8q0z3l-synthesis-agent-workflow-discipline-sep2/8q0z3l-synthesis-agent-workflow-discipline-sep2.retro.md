---
id: 8q0z3l
title: "Synthesis: Agent Behavior, Workflow Discipline, and Process (Sep 2025 – Jan 2026)"
type: standard
tags: [synthesis]
created_at: "2026-03-01 23:24:00"
status: active
---

# Synthesis: Agent Behavior, Workflow Discipline, and Process (Sep 2025 – Jan 2026)

**Scope**: 23 retros covering agent file deletion, plan mode interference, domain tool bypass, premature optimization, workflow migrations, task planning, ADR lifecycle, task file corruption, and subtask workflows.
**Date range**: 2025-09-24 through 2026-01-06

## What Went Well

- **Systematic, incremental approach** (Identified in 18/23 retros): Breaking work into phases (research, plan, execute) with incremental commits and continuous validation consistently led to successful outcomes. Sessions that followed task-driven development with clear behavioral specifications delivered the best results.

- **Protocol-based architecture and tool reuse** (Identified in 12/23 retros): The migration to ace-nav's wfi://, tmpl://, and guide:// protocols consistently proved valuable, making workflows location-agnostic and discoverable. Reusing existing implementations instead of duplicating logic was repeatedly identified as a success pattern.

- **Git history as safety net** (Identified in 8/23 retros): Using git history for recovery from corruption, accidental deletions, and failed edits saved work in multiple sessions. The pattern of `git show`, `git checkout`, and `git log --diff-filter` proved essential.

- **Clean architecture and separation of concerns** (Identified in 10/23 retros): The molecule/organism/atom pattern, three-layer architecture (workflow/command/CLI), and clear domain boundaries consistently produced maintainable code.

- **User feedback as course correction** (Identified in 9/23 retros): Quick user feedback during sessions prevented errors from compounding. Sessions that incorporated iterative user validation produced significantly better outcomes.

- **Subtask orchestrator pattern** (Identified in 3/23 retros): Breaking large tasks into orchestrator + subtasks with focused scope, separate branches/worktrees, and <500-line PRs enabled focused work and easier reviews.

## What Could Be Improved

- **File corruption and data loss from unsafe operations** (Identified in 8/23 retros): YAML frontmatter corruption, accidental file deletions, and unsafe File.write operations caused repeated data loss. The Edit tool's string matching is fragile for structured data, and large file edits (1000+ lines) are especially prone to corruption.

- **Incomplete migrations and partial updates** (Identified in 7/23 retros): When migrating libraries, protocols, or commands, call sites were frequently missed. Partial migrations created silent failures, data corruption risks, and confusion. Grep-based verification was identified as essential but not consistently applied.

- **Bypassing domain tools for manual file operations** (Identified in 6/23 retros): Using Write/Edit tools or manual file operations (git mv, rm -rf, sed) instead of ace-taskflow CLI commands caused invalid task IDs, schema violations, lifecycle bypasses, and renumbering chaos.

- **Incorrect assumptions about architecture and APIs** (Identified in 8/23 retros): Making assumptions about CLI syntax, API existence, naming conventions, and architectural patterns without verification led to wasted work, incorrect documentation, and implementation rework.

- **Workflow naming and semantic collisions** (Identified in 3/23 retros): The /ace:plan-task workflow name collided with Claude Code's built-in "plan mode" concept. Command type confusion between Claude commands and bash commands caused repeated errors.

- **Test coverage gaps** (Identified in 6/23 retros): Tests mocking subprocess calls missed integration bugs. Automated tests not consistently written alongside implementation. Tests depending on real project state were slow and non-deterministic.

## Key Learnings

- **Always use domain-specific tools** (from 6 retros): When ace-taskflow or other ace-* tools exist for an operation, they must be used instead of manual file manipulation. Domain tools enforce schema, prevent invalid formats, and maintain consistency. Treating domain-managed files as generic text files is the single most destructive anti-pattern observed.

- **Verify before acting: research before execution** (from 10 retros): Always verify actual CLI syntax against --help, check if APIs exist by grepping the codebase, validate architectural assumptions before planning, and search for existing implementations before writing new code.

- **Incomplete migrations are dangerous** (from 4 retros): When migrating to a new library or pattern, ALL call sites must be updated. A simple `grep` for the old pattern after migration is essential. Partial migration creates silent data corruption risks.

- **Three-layer architecture clarity** (from 3 retros): Workflows (.wf.md) are for agent-driven write operations, Claude commands are triggers mapping to ace-nav invocations, CLI tools are for human-friendly read-only queries. Confusing these layers leads to scope creep.

- **Never delete files you did not create** (from 2 retros): Unauthorized file deletion or "cleanup" of files outside the current task scope is the most severe trust violation. Always assume unknown files are important unless explicitly told otherwise.

- **YAML frontmatter requires structured editing** (from 3 retros): String-based find/replace is unreliable for YAML frontmatter. A proper YAML parser should be used for metadata updates. SafeFileWriter with atomic writes and backups prevents corruption.

- **Subtask orchestrator pattern delivers value** (from 3 retros): Breaking large tasks into orchestrator + subtasks with focused scope, separate branches/worktrees, and <500-line PRs enables focused work, easier reviews, and parallel potential.

## Action Items

- **Enforce domain tool usage** (from 6 retros): Make it a mandatory check before any file operation in .ace-taskflow/ or other ace-* paths to use the corresponding CLI tool. Document this rule prominently in CLAUDE.md. Consider guardrails that warn when Write/Edit tools target domain-managed paths.

- **Implement migration verification checklists** (from 5 retros): After any migration, run grep for old patterns (File.write, old path references, deprecated tool names) to verify completeness. Formalize as a step in migration workflows.

- **Build SafeFileWriter/YAML-aware updates into tooling** (from 4 retros): Replace all raw File.write calls with SafeFileWriter across ace-* gems. Create commands for structured frontmatter updates using proper YAML parsing.

- **Add pre-flight verification to workflows** (from 6 retros): Before executing any workflow, verify CLI syntax with --help, check that referenced APIs exist, and validate architectural assumptions against existing patterns.

- **Implement subtask workflow support in ace-taskflow** (from 3 retros): Create CLI support for subtask creation, orchestrator templates, and subtask ID sequencing. Update existing workflows for subtask awareness.

- **Resolve workflow naming collisions** (from 2 retros): Rename plan-task to avoid collision with Claude Code's built-in plan mode. Add explicit metadata to documentation-only workflows.

- **Establish strict scope boundaries for file operations** (from 3 retros): Before any destructive action, apply checklist: (1) Did I create this file? (2) Is it part of the current task? (3) Do I have explicit user permission? If any answer is no, do not proceed.

## Additional Context

**Source retro IDs** (23 total):
8kn000, 8ko000, 8kp000 (×2), 8l0000, 8l1000 (×5), 8ld000 (×3), 8ln000, 8mf000, 8mq000, 8mr000, 8nj000, 8nm000 (×3), 8nq000, 8o5000

**Dominant themes**: The retros trace an evolution from initial workflow migrations (Sep 2025) through tool maturation (Oct–Nov 2025) to architectural refinement (Dec 2025 – Jan 2026). The most persistent anti-patterns — bypassing domain tools, incomplete migrations, and unsafe file operations — recur across the entire timeline, warranting highest priority for systemic fixes. The most consistent success patterns — incremental development, protocol-based architecture, and user feedback loops — should be preserved and reinforced.

**Most severe anti-pattern**: Bypassing domain tools for manual file operations. This pattern caused task ID renumbering chaos (8o5000), YAML frontmatter corruption (8ld000), unauthorized file deletion (8mf000), and lifecycle bypass issues across multiple retros.
