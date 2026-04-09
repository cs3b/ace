# Goal 6 — Structured Output Integration

## Goal

Use `ace-b36ts` JSON output as direct input to `jq` and save proof that downstream
consumption succeeded.

## Workspace

Save all output to `results/tc/06/` with this contract:

- `encode.json` — raw JSON from `ace-b36ts`
- `jq-length.txt` — `jq`-extracted array length
- `jq-first.txt` — first generated ID extracted by `jq`

## Constraints

- Use this deterministic command intent:
  - generate three IDs with JSON output using `--count 3 --format day --json` and a fixed timestamp.
- Use `jq` directly against the generated JSON file (no sed/awk/manual parsing).
- Ensure extracted values come from actual `jq` execution.
- Do not fabricate output.
