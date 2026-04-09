# Goal 6 — JSON Output with Task Metadata

## Goal

List worktrees in JSON format and verify that task-associated entries include task_id and branch fields, while non-task entries have null or missing task fields. Validate the JSON structure is well-formed.

## Workspace

Save all output to `results/tc/06/`. Capture:
- `results/tc/06/list-json.stdout`, `.stderr`, `.exit` — list in JSON format

Optional capture:
- `results/tc/06/json-analysis.md` — support summary of JSON structure noting task_id and branch fields per entry

## Constraints

- Using what you learned from Goal 1, invoke ace-git-worktree list with JSON format flag.
- Both task worktrees (8pp.t.q7w and 8pp.t.r8x) from previous goals should be present.
- Parse or inspect the JSON output to verify task metadata fields.
- Treat `list-json.stdout` as the primary oracle; `json-analysis.md` is support evidence only when present.
- All artifacts must come from real tool execution, not fabricated.
