# Goal 6 -- Status Watch Refresh Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):

- Confirm sandbox/project state impact first.
- Confirm explicit artifacts under `results/tc/06/`.
- Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

Checks:
1. **Required captures exist** -- baseline status, `watch.command.txt`, and watch command captures are present.
2. **Watch execution completed as a bounded session** -- bounded watch command exits with a controlled termination code (`0`, `124`, `130`, or `143`). Empty stderr is preferred, but bounded-session shutdown noise is acceptable when it is limited to Ruby/Open3 stream-closure messages (for example `IO#read: stream closed in another thread`) rather than product-level command errors.
3. **Refresh evidence exists** -- watch output shows repeated status frames/updates rather than a single static snapshot.
4. **Command contract is explicit** -- `results/tc/06/watch.command.txt` records that the command under test was `ace-overseer status --watch`.

## Verdict

- **PASS**: Status watch demonstrates observable refresh behavior with valid captures.
- **FAIL**: Missing captures, uncontrolled watch failure, or no refresh evidence.

Report: `PASS` or `FAIL` with evidence from the baseline, watch captures, and `watch.command.txt`.
