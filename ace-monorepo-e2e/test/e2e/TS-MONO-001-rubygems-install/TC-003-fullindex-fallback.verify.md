# Goal 3 — Full-Index Fallback Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Core fallback artifacts captured** — `results/tc/03/fullindex.exit`, `results/tc/03/fullindex.stdout`, and `results/tc/03/fullindex.stderr` all exist.
2. **Install command result is valid** — `results/tc/03/fullindex.exit` is numeric.
3. **Fallback command contract is explicit** — `results/tc/03/install-command.txt` exists and includes `bundle install --full-index`.
4. **Success evidence (impact-first)** — If fallback exit is `0`:
   - `results/tc/03/installed-ace-gems.txt` exists and includes at least one `ace-*` entry, and `results/tc/03/Gemfile.lock` exists and contains at least one `ace-` gem dependency,
   - `results/tc/03/lockfile-receipt.json` and `results/tc/03/install-receipt.json` exist, parse as JSON, and the activated receipt's package paths point inside `results/tc/03/.gem` or `results/tc/03/.bundle` (no host/source paths).
5. **Consumer-only dependency edges** — For each of `ace-bundle`, `ace-review`, `ace-task`:
   - `results/tc/03/consumer/ace-bundle/Gemfile` exists, names only that consumer (ace-bundle), and contains no direct `ace-git-github` entry; `results/tc/03/consumer/ace-bundle/install.exit` exists and is numeric; when that exit is `0`: `results/tc/03/consumer/ace-bundle/Gemfile.lock` resolves `ace-git-github`, and `results/tc/03/consumer/ace-bundle/install-receipt.json` exists.
   - `results/tc/03/consumer/ace-review/Gemfile` exists, names only that consumer (ace-review), and contains no direct `ace-git-github` entry; `results/tc/03/consumer/ace-review/install.exit` exists and is numeric; when that exit is `0`: `results/tc/03/consumer/ace-review/Gemfile.lock` resolves `ace-git-github`, and `results/tc/03/consumer/ace-review/install-receipt.json` exists.
   - `results/tc/03/consumer/ace-task/Gemfile` exists, names only that consumer (ace-task), and contains no direct `ace-git-github` entry; `results/tc/03/consumer/ace-task/install.exit` exists and is numeric; when that exit is `0`: `results/tc/03/consumer/ace-task/Gemfile.lock` resolves `ace-git-github`, and `results/tc/03/consumer/ace-task/install-receipt.json` exists.
6. **Failure evidence** — If fallback exit is non-zero:
   - `results/tc/03/install-summary.txt` exists.
   - `results/tc/03/fullindex.stdout` or `results/tc/03/fullindex.stderr` contains actionable error details.
   - Missing receipts are consistent with a failed install and are not themselves a failure in this case.
7. **Placeholder rule** — Pre-created placeholder files (empty `install-summary.txt`, `Gemfile.lock`, `installed-ace-gems.txt`, `bundle-list.*`) are verifier input contracts, not postcondition evidence. On failure, ignore their contents and timestamps; never fail a goal solely because placeholders are empty or older than the command. Judge success end-state only from artifacts written after a successful install.

The per-package exact versions are Goal 4's machine-readable acceptance, not this goal's bar.

## Verdict

- **PASS**: Required artifacts exist, evidence is consistent with fallback install outcome and installed gem end state, and consumer-only resolutions are present with their dependency-edge evidence.
- **FAIL**: Missing/invalid exit evidence, missing fallback command evidence, missing success end-state proof, missing consumer-edge artifacts on a successful install, or missing actionable failure details.

Report: `PASS` or `FAIL` with evidence (exit code value, key output snippets).
