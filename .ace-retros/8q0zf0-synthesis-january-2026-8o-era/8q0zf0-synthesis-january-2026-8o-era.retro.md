---
id: 8q0zf0
title: "Synthesis: January 2026 (8o-era) — CLI Migration, Config Architecture, and Agent Discipline"
type: standard
tags: [synthesis]
created_at: "2026-03-01 23:36:40"
status: active
---

# Synthesis: January 2026 (8o-era) — CLI Migration, Config Architecture, and Agent Discipline

**Date**: 2026-03-01
**Context**: Synthesis of 46 retros from the 8o B36TS era (January 2026), covering the Thor-to-dry-cli migration, ace-support-* gem renames, configuration architecture work, test performance optimization, and agent behavior patterns.
**Author**: Claude Opus 4.6
**Type**: Standard | Synthesis
**Source retros**: 46 active retros with IDs 8o0000–8ouo8f

## What Went Well

### 1. CLI Framework Migration Was Methodically Executed (Identified in 8/46 retros)

The Thor-to-dry-cli migration (Task 179) followed a disciplined spike-first approach: ace-search served as proof-of-concept, reusable infrastructure was built in ace-support-core before migrating individual gems, and behavioral parity was maintained throughout. Key patterns established — numeric type conversion, positional arguments handling, default command routing, `CLI.start` with `known_command?` — became the foundation for all 15+ CLI gems. The subsequent Hanami CLI pattern migration further cleaned up wrapper patterns.

**Source retros**: 8o4000, 8o5000 (Thor), 8o6000 (dry-cli, PR #135), 8o8vs8, 8o90e2, 8odvjc, 8ocnmm, 8opupa

### 2. Gem Rename Operations Developed a Repeatable Process (Identified in 5/46 retros)

The ace-support-* naming convention rollout (Tasks 202.02–202.04, 217) established patterns for large-scale gem renames: backward compatibility shims with deprecation warnings, multi-round code-deep reviews, proper ace-support-* directory structures (`lib/ace/support/<name>/`), and batch update verification. By the third rename (ace-nav → ace-support-nav), the process was well-understood even if execution remained labor-intensive.

**Source retros**: 8oamg4, 8ob0vl, 8ob14g, 8oj009, 8oews3

### 3. Test Performance Optimization Achieved Dramatic Results (Identified in 4/46 retros)

Systematic profiling with `ace-test --profile` consistently identified the root cause: subprocess calls in unit tests. The MockGitRepo pattern for ace-git-secrets achieved 75% reduction (21s → 5.3s). The ace-lint optimization achieved 97% reduction (2.1s → 69ms). Cache pre-warming patterns eliminated random slowness caused by test-order-dependent cache invalidation.

**Source retros**: 8o2000 (PR #110), 8oums2, 8ouo8f, 8otpzb

### 4. Iterative Code Review Found Real Issues (Identified in 6/46 retros)

Multi-round code-deep reviews with multiple LLM models consistently caught critical bugs that single-pass reviews missed. Different models found different issues (codex-max found Rakefile issues, claude-opus found gem root path issues). The pattern of 2-3 review iterations became standard practice.

**Source retros**: 8o6000 (PR #135), 8ocls2, 8ob0vl, 8ob14g, 8oews3, 8onxo5

### 5. Workflow Context Embedding Reduced Tool Calls Significantly (Identified in 2/46 retros)

The `embed_document_source: true` pattern changed the paradigm from "instructions to gather context" to "instructions with context already included," reducing `/ace:commit` from 5 tool calls to 2 (60% reduction).

**Source retros**: 8o2000 (Workflow Context Embedding), 8o2000 (Task 153)

## What Could Be Improved

### 1. Automated Refactoring Scripts Repeatedly Produced Malformed Code (Identified in 5/46 retros)

sed-based and Python-based namespace replacement scripts created malformed Ruby module structures, incorrect indentation, and corrupted files across multiple gem rename operations. This was the single most time-consuming recurring issue — each rename required multiple fix cycles for automated replacements.

**Source retros**: 8oamg4, 8ob0vl, 8ob14g, 8oews3, 8odvjc

### 2. File.expand_path Level Counting Was Error-Prone (Identified in 3/46 retros)

During gem renames, calculating the correct number of `../` levels for `File.expand_path` from deeply nested files was repeatedly wrong. Path level counting corrections went through 3-4 iterations (4→5→6→5) before reaching the correct value.

**Source retros**: 8ob0vl, 8ob14g, 8onxo5

### 3. PR Target Branch Misconfiguration Recurred (Identified in 3/46 retros)

Subtask PRs targeting `main` instead of the orchestrator branch was a recurring problem. Despite being identified and documented, the pattern recurred because the tooling didn't enforce correct targeting.

**Source retros**: 8oan5a, 8ocls2, 8ortz8

### 4. CHANGELOG Preservation During Rebase Was Fragile (Identified in 2/46 retros)

Manual CHANGELOG conflict resolution during squash-and-rebase operations led to silent truncation — writing only ~76 lines instead of all ~350 lines. The verification step (`diff CHANGELOG.md CHANGELOG.md.backup`) was skipped under time pressure.

**Source retros**: 8ocvll, 8ohe41

### 5. Agent Over-Explored Before Acting on Explicit Instructions (Identified in 3/46 retros)

When given fully-specified instructions (exact file path, exact content, exact location), the agent still launched extensive exploration phases — 63 tool calls for a task requiring 3. This represents a 20x efficiency problem for simple, well-defined tasks.

**Source retros**: 8oqv3w, 8oq2xv, 8ohhwc

### 6. Task Scope Estimation Was Consistently Low (Identified in 4/46 retros)

Tasks estimated at 4-8 hours regularly expanded into multi-subtask efforts. "Out of Scope" items frequently turned out to be on the critical path. The "Leave for Future" trap repeatedly caught items that were actually immediate dependencies.

**Source retros**: 8ot1ve, 8odvjc, 8o0000, 8o4000

## Key Learnings

### Architecture & Configuration

1. **Cascade vs Scan are fundamentally different** — ConfigFinder walks UP (cascade), but project-wide discovery needs to scan DOWN. Patching cascade resolution for discovery problems is architecturally wrong. (8oq2xv — identified across 2 retros)

2. **Migration preserves patterns by default** — Framework migrations naturally carry over pre-existing patterns unless explicitly scoped otherwise. The wrapper pattern from Thor survived into dry-cli because the migration was framed as "swap framework" not "modernize architecture." (8o8vs8 — identified in 2 retros)

3. **ace-support-* gems must use `lib/ace/support/<name>/` structure** — This is a hard convention discovered through multiple painful renames. (8ob0vl, 8ob14g — identified in 3 retros)

4. **Pre-release semver: breaking changes use minor bump, not major** — For 0.x gems per ADR-024, major bumps are incorrect. (8ob0vl, 8ob14g — identified in 2 retros)

### Testing

5. **Subprocess calls are silent performance killers** — Tests that look fast on the surface can be slow if they don't stub the *entire* call chain. Always stub at the outermost boundary (`available?` + `capture3`, not just one). (8oums2, 8ouo8f — identified in 4 retros)

6. **Random test slowness = cache invalidation problem** — When different tests are slow each run, the issue is shared mutable state + Minitest shuffle. Each test must be self-sufficient. (8ouo8f — identified in 2 retros)

7. **Exit-code-only testing creates false confidence** — State machine tests that only check exit codes can pass while the state machine is completely broken. Must assert internal state transitions. (8orvks, 8orx1n — identified in 3 retros)

### Git Operations

8. **Always use `git checkout --theirs` for CHANGELOG conflicts** — Manual rewriting during conflict resolution silently truncates content. Verification with `wc -l` before and after is mandatory. (8ocvll — identified in 2 retros)

9. **Cherry-pick > rebase --onto for selective commit migration** — When branch has mixed commit types and target has diverged significantly, cherry-pick offers better control. (8os0p5 — identified in 1 retro)

10. **Grouping by config signature alone is wrong for split commits** — Different scopes with identical configs get merged. Must include scope name in grouping key. (8opupa — identified in 2 retros)

### Agent Discipline

11. **ALWAYS use domain-specific tools** — Using `Write` to create task files instead of `ace-taskflow task create` bypasses all schema validation and creates maintenance burden. Created invalid triple-decimal task IDs (`179.00.1`). (8o5000, 8o8u8l — identified in 3 retros)

12. **Explicit plans don't need exploration** — When instructions provide exact file path, exact content, exact location, and verification command: execute immediately. (8oqv3w — identified in 2 retros)

13. **"Implement plan" ≠ "write code" during spec creation** — Agents interpret "implement task" as "write code" when only spec files are requested. Explicit "DO NOT IMPLEMENT CODE" prohibitions needed in draft/plan workflows. (8oloax — identified in 2 retros)

14. **Multi-step workflows must be externalized BEFORE starting work** — Without TodoWrite for tracking, agents treat detailed implementation plans as the "primary instruction" and lose the higher-order workflow. (8ohhwc — identified in 1 retro)

## Action Items

### Stop Doing

- **Using sed/Python scripts for Ruby namespace changes without single-file testing first** (5 retros: 8oamg4, 8ob0vl, 8ob14g, 8oews3, 8odvjc)
- **Creating task/domain files manually with Write tool** — always use `ace-taskflow` commands (3 retros: 8o5000, 8o8u8l, 8olqpc)
- **Writing tests that call `system()` or `Open3` without stubbing** (4 retros: 8o2000, 8oums2, 8ouo8f, 8otpzb)
- **Manually writing full CHANGELOG content during conflict resolution** (2 retros: 8ocvll, 8ohe41)
- **Exploring codebases when instructions are explicit and complete** (3 retros: 8oqv3w, 8oq2xv, 8ohhwc)
- **Treating framework migrations as purely mechanical find-and-replace** (2 retros: 8o8vs8, 8o4000)
- **Marking "Out of Scope" items that are actually on the critical path** (2 retros: 8ot1ve, 8o0000)
- **Creating subtask PRs targeting `main` without checking task hierarchy** (3 retros: 8oan5a, 8ocls2, 8ortz8)

### Continue Doing

- **Spike-first approach for framework migrations** — establish patterns on one gem before broad rollout (3 retros: 8o6000, 8o8vs8, 8odvjc)
- **Multi-round code-deep reviews with multiple LLM models** — different models catch different issues (6 retros)
- **Systematic test profiling with `ace-test --profile`** before optimization work (4 retros)
- **Creating subtasks when scope legitimately expands** rather than bloating original task (3 retros: 8ot1ve, 8o0000, 8odvjc)
- **Atomic commits for each logical change** (3 retros: 8oa1ev, 8ohe41, 8oj009)
- **Backward compatibility shims with deprecation warnings** during gem renames (3 retros)

### Start Doing

- **Add audit subtask to every migration task** — verify compliance after migration, not just API changes (2 retros: 8o0000, 8o4000)
- **Run `ruby -c` on all modified .rb files before committing automated replacements** (3 retros: 8oamg4, 8ob0vl, 8ob14g)
- **Add "Usage Scenario Walkthrough" to task specs** — simulate single, batch, and scale execution before scoping (2 retros: 8ot1ve, 8oom7r)
- **Check instruction completeness before deciding to explore** — exact path + content + location + verification = execute immediately (2 retros: 8oqv3w, 8ohhwc)
- **Add explicit "DO NOT IMPLEMENT CODE" sections to draft/plan workflows** (2 retros: 8oloax, 8olqpc)
- **Pre-warm caches at test suite startup and make stub helpers pre-populate caches** (2 retros: 8oums2, 8ouo8f)
- **Always run `gh pr view --json baseRefName` before PR operations** (3 retros: 8oan5a, 8ocls2, 8ocvll)
- **Add performance thresholds to CI** — fail if any unit test > 100ms (2 retros: 8oums2, 8ouo8f)

## Technical Patterns

### The Stub-at-Boundary Pattern (Test Performance)

```ruby
# WRONG: stubs inner method but not outer check
Open3.stub(:capture3, mock_result) { runner.run("test.rb") }

# RIGHT: stub at outermost boundary
Runner.stub(:available?, true) do
  Open3.stub(:capture3, mock_result) do
    runner.run("test.rb")  # Now fast — no subprocess
  end
end
```
*Identified in 4 retros (8o2000, 8oums2, 8ouo8f, 8o90e2)*

### The dry-cli SystemExit Pattern (CLI Testing)

```ruby
def invoke_cli(cli_class, args)
  stdout, stderr = capture_io do
    begin
      @_cli_result = cli_class.start(args)
    rescue SystemExit => e
      @_cli_result = e.status
    end
  end
  { stdout: stdout, stderr: stderr, result: @_cli_result }
end
```
*Identified in 2 retros (8o90e2, 8o6000)*

### The CHANGELOG Conflict Resolution Pattern (Git)

```bash
git checkout --theirs CHANGELOG.md
wc -l CHANGELOG.md CHANGELOG.md.backup   # Verify line counts
head -30 CHANGELOG.md.backup              # Check entries to insert
# Edit surgically to insert new entries
diff CHANGELOG.md CHANGELOG.md.backup     # Final verification
git add CHANGELOG.md
```
*Identified in 2 retros (8ocvll, 8ohe41)*

## Thematic Summary

| Theme | Count | Key Pattern |
|-------|-------|-------------|
| CLI Migration (Thor→dry-cli→Hanami) | 8 retros | Spike-first, reusable infrastructure, behavioral parity |
| Gem Renames & Namespace Migration | 5 retros | Backward compat shims, multi-round review, sed is fragile |
| Configuration Architecture | 4 retros | Cascade ≠ scan, audit post-migration, config test mode limited value |
| Test Performance Optimization | 4 retros | Profile first, stub at boundary, pre-warm caches |
| Git/PR Operations & CHANGELOG | 6 retros | Target branch validation, CHANGELOG preservation, cherry-pick > rebase |
| Agent Behavior & Discipline | 6 retros | Use domain tools, don't over-explore, externalize workflows |
| E2E Testing & Coworker System | 5 retros | Assert state not exit codes, report separation, review quality |
| Documentation & Workflow | 6 retros | Context embedding, skills migration, formatting conventions |
| Scope & Estimation | 4 retros | "Out of Scope" trap, usage scenario walkthroughs, audit subtasks |

## Additional Context

- **Time period**: January 1-31, 2026 (B36TS range 8o0000–8ouo8f)
- **Source retro count**: 46 active retros synthesized
- **Major work streams**: Thor→dry-cli migration (Task 179), ace-support-* renames (Task 202), config architecture (Task 157/228), ace-coworker MVP (Task 229/237), E2E test infrastructure (Task 221)
- **Previous synthesis**: 8q0z2p–8q0z3l covered Sep 2025–Jan 2026 broadly; this synthesis focuses specifically on the dense January 2026 8o-era
