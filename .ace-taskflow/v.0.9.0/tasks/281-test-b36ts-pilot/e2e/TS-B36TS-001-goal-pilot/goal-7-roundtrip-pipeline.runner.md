# Goal 7 — Roundtrip Pipeline

## Goal

Encode a known date, then pipe or feed the encoded result into the decode operation — all through a shell pipeline or command substitution. Save a file with the original date, the encoded token, and the decoded result, proving the roundtrip works end-to-end.

## Workspace

Save output to `results/7/`. The file should contain all three values: the original date, the encoded token, and the decoded result.

## Constraints

- Using the encode and decode operations you've already exercised in Goals 2–3, compose them into a pipeline.
- The encode→decode must happen through shell pipeline (`|`) or command substitution (`$(...)`) — not by manually copying the encoded value.
- Do not fabricate output — all values must come from actual tool execution.
- The original date should be a specific, known date (not "today" — use a fixed date so the roundtrip can be verified).
