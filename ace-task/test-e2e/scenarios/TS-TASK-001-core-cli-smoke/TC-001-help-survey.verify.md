# Goal 1 - Help Survey Verification

## Injected Context

The verifier receives the `results/` directory tree and sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm command outputs were captured under `results/tc/01/`.
2. Confirm help survey captured all requested command surfaces.
3. Use stderr/exit files as fallback evidence.

1. `help.exit`, `create-help.exit`, `update-help.exit`, and `doctor-help.exit` all exist and are `0`.
2. `help.stdout` includes `create`, `update`, `doctor`, `status`, and `plan`.
3. Command help outputs reference command-specific options/usage text.

## Verdict

- **PASS**: All captures exist, exits are zero, and help content includes expected commands.
- **FAIL**: Missing captures, non-zero exits, or incomplete command discovery.
