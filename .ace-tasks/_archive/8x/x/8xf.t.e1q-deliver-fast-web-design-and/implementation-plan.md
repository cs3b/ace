# Implementation plan

## Task Summary
Deliver reviewed tasks .0/.1/.2; native remains future.

## Execution Context
Use codex/ace-design worktree. Source-owned skills, shared self-contained workflow bindings, Ruby ATOM layout, bin/ace-* commands and source-scoped commits.

## Technical Approach
Ruby owns config, session/gallery validation, catalog validation and CLI. Node built-in HTTP owns loopback static preview; a separate pinned Playwright/axe runner owns inspection. No LLM orchestration in Ruby. Agents own creativity and feedback. Plain JSON/Markdown interchange. Existing ace-search retrieves curated cards.

## File Modifications
Create ace-design gem with lib/ace/design/{atoms,molecules,organisms,cli}, exe, browser runner and locked dependencies, handbook skills/workflows/catalog/templates, docs, fast/feat tests. Register Gemfile, bin/ace-design, nav source configs, test suite and docs/blueprint/tools/package overview.

## Plan Checklist
- step_01: task .0 Success Criteria: package scaffold + session/gallery CLI + explore workflow; depends []; verify bin/ace-test ace-design fast and real preview feature tests.
- step_02: task .1 Success Criteria: implement/audit workflows + runtime doctor + browser inspector with honest evidence; depends [step_01]; verify bin/ace-test ace-design all including real browser.
- step_03: task .2 Success Criteria: inspiration workflow, source ledger/proposal templates, curated catalog and benchmark fixtures; depends [step_01]; verify validate and source/projection contract tests.
- step_04: parent Success Criteria: installed gem discovery/CLI smoke, independent review, corrections, complete deterministic suite, scoped commits and delivery report; depends [step_02,step_03].

## Test Plan
See test-plan.md. Boundary tests in fast, real browser and CLI in feat, live subjective benchmarks explicitly separate.

## Risk Assessment
A passing inspector is not proof of UX/taste. Report automatic findings and coverage separately from human/agent critique. Preview server must not expose files outside session. Pin runtime dependencies and fail explicitly when missing.

## Freshness Summary
Inputs: design-plan.md, three reviewed .s.md files, readiness-review.md, test-plan.md, existing ACE CLI/config/nav/handbook source. Current at adcfc19d8.

## Planning tool evidence
Configured role:planner uses Pi CLI; ace-task plan .0 exceeded explicit 150s deadline. Use this checklist plus the user-approved plan and independently reviewed specs as the execution plan rather than increasing deadlines. No task requirement is dropped.
