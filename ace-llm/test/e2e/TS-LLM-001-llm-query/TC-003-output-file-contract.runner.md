# Goal 3 — Output File Contract

## Goal

Run `ace-llm gflash --prompt "Write only token OUTPUT_OK" --output results/tc/03/response.md --format markdown`
and capture evidence for output-file behavior on success or explicit provider/auth failure.

## Workspace

Save artifacts to `results/tc/03/`.

## Constraints

- Preserve raw output exactly.
- Do not pre-create the expected output file.
- If provider credentials are missing, capture explicit auth/config failure evidence.
