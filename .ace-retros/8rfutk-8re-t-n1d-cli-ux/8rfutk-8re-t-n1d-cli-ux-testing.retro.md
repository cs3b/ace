---
id: 8rfutk
title: 8re-t-n1d-cli-ux-testing
type: standard
tags: [ace-tmux, cli, ux, testing]
created_at: "2026-04-16 20:32:51"
status: active
---

# 8re-t-n1d-cli-ux-testing

## What Went Well

- The debugging got materially clearer once the problem was split into separate buckets instead of treated as one flaky tmux issue: invalid pane syntax, dotted window-name resolution, and interactive TUI submit/capture behavior each needed a different fix.
- The package-level fast suite was strong enough to absorb the refactor without slowing the loop down. Resolver, model, builder, and control-surface tests made it safe to tighten target parsing and add interactive-pane behavior.
- Live tmux checks were used where they actually mattered: confirming dotted window names, visible-tail capture, and the difference between shell panes and Codex panes. That kept the implementation grounded in user-visible behavior instead of only mocks.
- Updating docs and CLI help alongside the code reduced repeat confusion. The final surface now teaches supported `--pane` forms, explains interactive CLI pacing, and clarifies that TUI capture is screen-tail oriented rather than generic scrollback.

## What Could Be Improved

- The original CLI UX let malformed pane targets fall through to tmux, which produced errors like `can't find window: 3:1`. That is avoidable friction; control-side commands should validate operator-facing target syntax before dispatch.
- `--capture` semantics were too vague. "Last N lines" sounds obvious, but for a TUI it matters whether that means history tail or visible screen tail. That ambiguity made it look like `Enter` had not been submitted when the real problem was stale capture.
- Mock-heavy confidence came a little earlier than it should have for the Codex case. Interactive panes are different enough from shell panes that one real acceptance check should be considered part of the fix, not an optional extra.
- `--cmd` reads like "run a shell command", but in a Codex pane it sends prompt text to the agent unless the provider-specific shell escape is used. The CLI currently works, but the UX contract is still easy to misread.

## Key Learnings

- Input grammar is part of the product UX. If a pane target format is invalid, the error needs to teach the correct form immediately instead of delegating explanation to tmux internals.
- Interactive AI panes are not just another shell pane. They need submit pacing and visible-screen capture semantics, while generic shells still benefit from immediate send behavior and history-tail capture.
- Testing should mirror that contract split. Fast tests are the right place for parsing, target normalization, pacing rules, and capture strategy selection; live tmux checks should prove only the handful of behaviors that depend on real screen state.
- When operator reports conflict with mocked expectations, the first question should be "what exactly is visible in the pane right now?" rather than "which key sequence should we send next?" The visible-state model was the missing piece here.

## Action Items

### Stop Doing

- Letting raw tmux error messages be the first feedback for invalid operator input when ACE can validate and correct the format itself.
- Treating shell-oriented capture assumptions as automatically valid for full-screen TUIs.

### Continue Doing

- Pairing fast deterministic tests with a small number of real tmux checks for user-facing control features.
- Updating command help and usage docs in the same change set as CLI behavior fixes.
- Using user-provided live command transcripts to separate product UX bugs from environment misunderstandings.

### Start Doing

- Add explicit docs/examples that distinguish shell-pane `--cmd` usage from interactive-agent-pane usage, including provider shell escapes such as Codex `!command`.
- Add a reusable live or pseudo-TUI regression fixture for submit pacing and visible-tail capture so future changes do not rely on memory of the Codex behavior.
- Consider a small operator hint when `--cmd` targets a detected interactive CLI pane, so the command contract is obvious before the user assumes shell semantics.
