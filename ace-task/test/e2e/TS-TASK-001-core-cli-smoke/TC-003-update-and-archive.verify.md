# Goal 3 - Update and Archive Movement Verification

## Injected Context

The verifier receives the `results/` directory tree and sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm archive tree includes task spec files.
2. Confirm update/show captures exist under `results/tc/03/`.
3. Use runner observations to disambiguate which task ref was updated when needed.
4. Use debug captures as fallback.

1. `update.exit` is `0`.
2. `.ace-tasks/_archive/` contains at least one archived task spec file after the update.
3. `update.stdout` includes update or archive confirmation text.

## Verdict

- **PASS**: Update succeeds and archive relocation evidence exists.
- **FAIL**: Update fails or archive evidence is missing.
