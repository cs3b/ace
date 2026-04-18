# Goal 6 Verification - Cache diff after refresh

## Expectation

Two sync passes with changed fixture payload produce a usable diff report. If the
refresh payload is malformed, the run may still pass when the tool surfaces that
parse failure explicitly and the diff command remains usable.

## PASS Criteria

- `results/tc/06/sync-initial.exit` is `0`
- `results/tc/06/diff.exit` is `0`
- `results/tc/06/diff.stdout` includes at least one user-facing diff summary token, such as:
  - `Added`, `Removed`, `Changed`, `No changes`
  - `New providers:`, `Removed providers:`
  - `New models:`, `Removed models:`
- and one of these refresh outcomes is true:
  - `results/tc/06/sync-refresh.exit` is `0`
  - `results/tc/06/sync-refresh.exit` is non-zero and `results/tc/06/sync-refresh.stderr`
    clearly reports a JSON parse failure
