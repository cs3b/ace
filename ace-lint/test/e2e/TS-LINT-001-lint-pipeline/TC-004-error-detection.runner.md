# Goal 4 — Error Detection

## Goal

Lint a fixture that definitely violates the active lint configuration and verify the tool reports the problem with a non-zero exit code and generates a pending report artifact.

## Workspace

Save all output to `results/tc/04/`. Capture:
- the command's stdout, stderr, and exit code
- a copy of the generated pending report, if one exists
- the exact target file path being linted
- the active working directory / config location used for the run

## Constraints

- Using what you learned from Goal 1, invoke the lint operation on the known failing fixture, not the clean fixture.
- The runner must make it obvious which file was linted and from which directory/config context the command ran.
- If the command succeeds unexpectedly, still preserve all stdout/stderr/exit artifacts and any generated report listing so the verifier can classify the mismatch.
- All artifacts must come from real tool execution, not fabricated.
