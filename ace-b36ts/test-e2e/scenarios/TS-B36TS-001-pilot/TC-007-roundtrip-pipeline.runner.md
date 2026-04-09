# Goal 7 — Roundtrip Pipeline

## Goal

Encode a fixed timestamp and immediately decode the produced token through a shell
pipeline or command substitution, proving roundtrip integrity.

## Workspace

Save output to `results/tc/07/` using this contract:

- `roundtrip.summary` with three lines:
  - `ORIGINAL=<timestamp>`
  - `TOKEN=<token>`
  - `DECODED=<decoded-value>`
- `roundtrip.stdout`, `roundtrip.stderr`, `roundtrip.exit`

## Constraints

- Use fixed original timestamp: `2025-01-06T12:30:00Z`.
- Encode then decode in one composed shell flow (`|` or `$(...)`) without manual token copy.
- Decode with an explicit format (`--format iso`) so the comparison is deterministic.
- Capture stdout/stderr/exit for the composed operation.
- Do not fabricate output.
