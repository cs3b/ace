---
id: 8q0z3i
title: "Synthesis: Git Operations, PR Workflow, and Code Review (Sep 2025 – Jan 2026)"
type: standard
tags: [synthesis]
created_at: "2026-03-01 23:23:54"
status: active
---

# Synthesis: Git Operations, PR Workflow, and Code Review (Sep 2025 – Jan 2026)

**Scope**: 27 retros covering squash-PR base branch bugs, commit reorganization, git worktree issues, PR false positives, review process, PR feedback, multi-model review, ace-search/ace-prompt, and synthesis quality.
**Date range**: 2025-10-01 through 2026-01-07

## What Went Well

- **Systematic debugging and investigation** (Identified in 20/27 retros): Agents consistently demonstrated thorough root cause analysis using multiple tools (Grep, Read, git log/reflog). Methodical tracing of code paths and hypothesis verification led to correct fixes.

- **Multi-model code review provides diverse value** (Identified in 10/27 retros): Using multiple LLM models (Claude, Codex, Gemini Pro) for code review caught different categories of issues. Each model found things others missed — Codex found filename collision bugs, Gemini found architecture issues, Claude found logic errors.

- **Backup branches before destructive git operations** (Identified in 6/27 retros): Creating backup branches/tags before rebases, squashes, and resets enabled successful recovery from mistakes. Git reflog was used effectively as a safety net.

- **User feedback as critical course correction** (Identified in 14/27 retros): User interventions consistently improved outcomes — catching spec mismatches, stopping premature solutions, correcting architectural assumptions, and redirecting work to the right problem.

- **Clean ATOM architecture adherence** (Identified in 8/27 retros): New features consistently fit into the Atoms/Molecules/Organisms architecture. Reviewers praised clean separation of concerns.

- **Incremental commits with clear messages** (Identified in 7/27 retros): Small, focused commits documenting progress at each stage made history readable and review manageable. Squashing into logical groups before merge kept history clean.

- **Immediate dogfooding of new tools** (Identified in 4/27 retros): Using newly built features to commit their own implementation or review their own code demonstrated real-world value and caught practical issues.

## What Could Be Improved

- **Wrong PR base branch / squash base assumed as origin/main** (Identified in 5/27 retros): PRs can target feature branches, not just main. Agents repeatedly used `origin/main` as the squash/rebase base without checking `gh pr view --json baseRefName`, causing cross-PR squashing, incorrect diff stats, and requiring full recovery.

- **LLM review false positives from diff-only context** (Identified in 6/27 retros): LLMs confidently asserted claims about codebase state they could not see (missing classes, security vulnerabilities, EOF issues). False positive rate reached 62.5% in one session, with Critical/High priority items being least reliable.

- **Premature solution proposals before root cause verification** (Identified in 7/27 retros): Jumping to code fixes before confirming whether the issue was a bug vs. configuration error, or before understanding the actual problem. Almost made code more lenient to work around config errors.

- **CLI flag/API assumptions without verification** (Identified in 6/27 retros): Documented or used CLI flags that did not exist (--search-root, --file), assumed API signatures without checking `--help`, and built integrations against assumed rather than actual interfaces.

- **Specification gaps leading to 25-30% rework** (Identified in 5/27 retros): Initial specs missed environmental compatibility (SSL, YAML types), CLI standards (--json output, exit codes), architecture references (ADRs), and edge cases. "Happy path" specs consistently underestimated actual work.

- **Incorrect git operations** (Identified in 5/27 retros): Pushed directly to main instead of feature branch, used `git reset --soft` instead of `git rebase -i` for mid-history reorganization, and performed destructive operations without verifying branch tracking.

- **CHANGELOG version management confusion** (Identified in 4/27 retros): Multiple incremental version entries during development, incorrect merge strategy during rebases, and Gemfile.lock not committed with version bumps.

- **Over-engineering initial designs** (Identified in 4/27 retros): First proposals were too complex (400+ line agents, JSON instead of markdown, multiple LLM calls instead of one). User corrections simplified designs significantly.

## Key Learnings

- **Always verify PR base branch before squash/rebase** (from 5 retros): Run `gh pr view $PR --json baseRefName` or `ace-git status` before any squash. PRs targeting feature branches instead of main is the most common destructive mistake.

- **Verify root cause before proposing code changes** (from 7 retros): Follow the "Stop-Think-Verify" protocol: (1) identify symptoms, (2) investigate code path, (3) determine bug vs. config error, (4) test with corrected configuration, (5) only then propose code changes.

- **LLM review findings require human verification** (from 6 retros): Never trust Critical/High priority LLM claims without grep/read verification. Diff-only context creates blind spots for file existence, class existence, and cross-file reference claims.

- **Check actual CLI flags with --help before documenting or integrating** (from 6 retros): Never assume flags exist based on similar tools. Run the tool's `--help`, test 2-3 commands, then document.

- **Interactive rebase is the correct tool for mid-history reorganization** (from 3 retros): `git reset --soft` removes ALL commits after the reset point including unrelated work. `git rebase -i` preserves commits outside the target range.

- **Tools provide data, workflows provide intelligence** (from 4 retros): Maintain clear separation — tools perform deterministic data gathering, workflows make decisions. Markdown reports are preferred over JSON for agent/human workflows.

- **Security must be proactive, not reactive** (from 4 retros): Command injection (use array syntax with Open3.capture3), path traversal, and input validation must be addressed during initial development, not discovered during code review.

- **Single source of truth prevents data drift** (from 3 retros): When two code paths need the same data, they must share the source. Parallel implementations guarantee drift and recurring bugs.

- **Specs should include environmental compatibility, ADR references, and CLI standards** (from 3 retros): "Happy path" specs miss approximately 25% of actual work.

## Action Items

- **Add PR base detection to squash-pr workflow as mandatory first step** (from 5 retros): Insert `gh pr view $PR --json baseRefName` as first prerequisite in squash-pr.wf.md. Add safety check warning when base is not origin/main.

- **Implement pre-push validation checklist** (from 5 retros): Before pushing, verify branch tracking with `git branch -vv`, confirm commits are not on main with `git log origin/main..HEAD`, and use explicit push syntax.

- **Add verification step for all Critical/High LLM review findings** (from 6 retros): Mandate grep/read verification before implementing any LLM-flagged fix. Consider adding `--full-files` option to ace-review to reduce false positives.

- **Create specification checklist template** (from 5 retros): Include environmental compatibility, architecture references, CLI standards, CI integration, and edge case enumeration.

- **Add "Stop-Think-Verify" protocol to debugging workflows** (from 7 retros): Before proposing code changes: determine if error indicates bug or config issue, test with known-good configuration, verify error message accuracy.

- **Include Gemfile.lock in version bump workflow** (from 3 retros): Update ace-bump-version.wf.md to commit root Gemfile.lock alongside version.rb and CHANGELOG.md.

- **Track and reduce LLM review false positive rate** (from 4 retros): Log false positive rates across reviews. Flag findings that require codebase verification versus diff-verifiable findings.

- **Classify developer feedback by action type** (from 2 retros): Auto-categorize PR comment feedback as bug, inconsistency, question, feature-request, or suggestion. Include bugs and inconsistencies in mandatory fix list.

## Additional Context

**Source retro IDs** (27 total):
8l0000, 8l4000 (×2), 8l6000, 8l7000 (×2), 8lc000, 8m0000, 8m3000 (×2), 8m8000, 8m9000, 8mc000, 8me000, 8n1000 (×2), 8n2000 (×2), 8n5000, 8n7000, 8nc000, 8no000, 8np000, 8nq000, 8nr000, 8ns000, 8o6000

**Dominant themes**:
1. Git workflow safety (branch verification, base detection, backup before destructive ops) — 12 retros
2. LLM review quality and verification — 10 retros
3. Specification completeness and requirements validation — 7 retros
4. Root cause verification before implementing fixes — 7 retros

**Key diagnostic principle**: The "Stop-Think-Verify" protocol emerged independently across 7 retros as the single most effective pattern for preventing wasted work in debugging and code review scenarios.
