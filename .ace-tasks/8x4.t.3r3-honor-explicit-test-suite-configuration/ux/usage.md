# Explicit suite configuration — draft usage

## API surface

CLI: existing `ace-test-suite -c FILE` / `--config FILE`. Configuration: the existing suite YAML schema; no new keys.

## Select an isolated suite

```bash
bin/ace-test-suite --config .ace-local/verification/assign-only.yml --parallel 1
```

Expected: only packages listed in this file execute, with the requested parallel override. Packages in the repository default suite do not join the run. Relative configuration paths resolve from the invoking working directory; package paths retain existing semantics.

## Reject an invalid explicit file

```bash
bin/ace-test-suite -c .ace-local/verification/missing.yml
```

Expected: a diagnostic names the requested file, nonzero exit status, zero package execution and no new successful suite result. A valid default suite does not supply a fallback. Malformed or unsupported suite structure has the same fail-before-execution contract.

## Preserve default execution

```bash
bin/ace-test-suite --parallel 1
```

Expected: existing default suite resolution and policy apply, with the current CLI override precedence. Omitting the flag intentionally retains default behavior.

Full package usage must be updated during implementation; these scenarios are acceptance contracts, not evidence that the repair already exists.
