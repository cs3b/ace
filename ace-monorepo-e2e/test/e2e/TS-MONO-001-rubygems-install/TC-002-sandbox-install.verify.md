# Goal 2 — Normal Bundle Install Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Core install artifacts captured** — `results/tc/02/install.exit`, `results/tc/02/install.stdout`, and `results/tc/02/install.stderr` all exist.
2. **Install command result is valid** — `results/tc/02/install.exit` is numeric.
3. **Command contract is explicit** — `results/tc/02/install-command.txt` exists and includes `bundle install` without `--full-index`.
4. **Success evidence (impact-first)** — If install exit is `0`:
   - `results/tc/02/installed-ace-gems.txt` exists and includes at least one `ace-*` entry, with `results/tc/02/Gemfile.lock` containing at least one `ace-` gem dependency,
   - `results/tc/02/lockfile-receipt.json` and `results/tc/02/install-receipt.json` exist, parse as JSON, and the activated receipt's package paths point inside `results/tc/02/.gem` or `results/tc/02/.bundle` (no host/source paths).
5. **Consumer-only dependency edges** — For each of `ace-bundle`, `ace-review`, `ace-task`:
   - `results/tc/02/consumer/<name>/Gemfile` exists, names only that consumer, and contains no direct `ace-git-github` entry,
   - `results/tc/02/consumer/<name>/install.exit` exists and is numeric,
   - when that exit is `0`: `results/tc/02/consumer/<name>/Gemfile.lock` resolves `ace-git-github`, and `results/tc/02/consumer/<name>/install-receipt.json` exists.
6. **Failure evidence** — If install exit is non-zero:
   - `results/tc/02/install-summary.txt` exists.
   - `results/tc/02/install.stdout` or `results/tc/02/install.stderr` contains actionable error details.
   - Missing receipts are consistent with a failed install and are not themselves a failure in this case.
7. **Placeholder rule** — Pre-created placeholder files (empty `install-summary.txt`, `Gemfile.lock`, `installed-ace-gems.txt`, `bundle-list.*`) are verifier input contracts, not postcondition evidence. On failure, ignore their contents and timestamps; never fail a goal solely because placeholders are empty or older than the command. Judge success end-state only from artifacts written after a successful install.

The per-package exact versions are Goal 4's machine-readable acceptance, not this goal's bar.

## Verdict

- **PASS**: Required artifacts exist, evidence is consistent with normal install outcome and installed gem end state, and consumer-only resolutions are present with their dependency-edge evidence.
- **FAIL**: Missing/invalid exit evidence, missing success end-state proof, missing consumer-edge artifacts on a successful install, or missing actionable failure details.

Report: `PASS` or `FAIL` with evidence (exit code value, key output snippets).
