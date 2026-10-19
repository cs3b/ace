# Mermaid change-map pilot evidence

Observed on 2026-10-19. The user accepted these examples as sufficient practical evidence to proceed with the lightweight workflow and improve through use.

| Pilot | Historical candidate | Published artifact | Observed result |
|---|---|---|---|
| Small PR #391: behavioral Markdown changes | `1022b796ceff43c1d9626ddcc6ae71e7c3eba25c` | [GitHub comment](https://github.com/cs3b/ace/pull/391#issuecomment-6257146226) | One flowchart renders in GitHub. It separates new agent reporting instructions from existing test-runner behavior. |
| Large PR #383: coworker, assignment and HITL flow | `579ea35916a56fe980687e0c9612a559b65f64b3` | [GitHub comment](https://github.com/cs3b/ace/pull/383#issuecomment-6257148020) | Overview and sequence diagram both render in GitHub. The overview identifies CLI/agent/instruction/state boundaries; the sequence exposes persistence-before-send and delivery retry ordering. |

## Checks performed

- Read the historical diffs and relevant surrounding code, Markdown instructions and recorded validation evidence. Checked 14 pinned source references against locally available Git objects.
- Rendered all three Mermaid blocks locally with a temporary Mermaid CLI installation, without adding a repository dependency.
- Posted the complete Markdown examples as explicitly authorized retrospective comments. Read back both published comments and inspected their GitHub-rendered diagrams in the browser. All three produced diagram output rather than syntax errors. GitHub supplies its own expand, zoom and pan controls.
- Preserved the source examples under `examples/` so future task execution has concrete acceptance references.

## What this establishes

Ordinary Markdown can expose important review questions in this repository's mixed CLI and agent-instruction flow. In particular, a resolved instruction path is not a model invocation, Markdown guidance is not atomic runtime enforcement, and successful work is distinct from successful notification delivery. The large example benefits from one focused sequence diagram in addition to the overview.

This was a retrospective authoring and rendering exercise, not a measured review-speed study or a new independent review verdict. Historical package tests were not rerun. It does not establish complete coverage of either PR or prove that the future create/update/reviewer integration works; those checks remain acceptance work in the draft task.
