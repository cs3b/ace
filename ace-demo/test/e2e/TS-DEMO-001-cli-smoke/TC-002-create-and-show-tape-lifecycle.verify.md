# Goal 2 - Create and Show Tape Lifecycle Verification

## Expectations

Validation order (impact-first):
1. Confirm artifacts under `results/tc/02/`.
2. Use debug captures only as fallback.

1. `create.exit` is `0` and `create.stdout` contains `Created:`.
2. `show.exit` is `0` and `show.stdout` contains `Tape: my-demo`.
3. `tape-ls.exit` is `0` and listing includes `my-demo.tape`.

## Verdict

- **PASS**: Tape was created and subsequently readable through CLI `show`.
- **FAIL**: Creation/show/lifecycle evidence is missing or inconsistent.
