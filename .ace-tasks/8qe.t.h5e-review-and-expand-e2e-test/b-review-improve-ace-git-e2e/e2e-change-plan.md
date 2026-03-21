## E2E Change Plan: ace-git

### Impact Summary
- **Current:** 1 scenario, 4 TCs
- **Proposed:** 1 scenario, 6 TCs
- **Net change:** +2 TCs (targeted coverage expansion, no removals)
- **Cost impact:** smoke tier retained; additional TCs are lightweight command-level checks

### Classification Decisions

#### KEEP
- `TC-001-git-status`
  - Keep baseline status behavior coverage in initialized repository context.
- `TC-002-git-diff`
  - Keep real working-tree diff behavior coverage.
- `TC-003-branch-info`
  - Keep branch metadata coverage.

#### MODIFY
- `TC-004-pr-summary.runner.md`
  - Clarify deterministic fallback behavior: prefer `ace-git pr`; if environment lacks PR context, require explicit fallback run (`ace-git status --no-pr`) and capture both attempts.
- `TC-004-pr-summary.verify.md`
  - Tighten acceptance criteria so PASS requires either valid PR metadata evidence or explicit no-PR fallback evidence with captured exit and output.
- `scenario.yml`
  - Extend `sandbox-layout` for new TCs 05 and 06.
- `runner.yml.md`
  - Include TC-005 and TC-006 in ordered runner bundle.
- `verifier.yml.md`
  - Include TC-005 and TC-006 in ordered verifier bundle and update final result count semantics.

#### REMOVE
- None.

#### CONSOLIDATE
- None.

#### ADD
- `TC-005-diff-output-path-security.runner.md`
  - Validate `ace-git diff --output ../../etc/passwd` fails with security/path validation signal.
- `TC-005-diff-output-path-security.verify.md`
  - Verify rejection evidence and non-zero exit capture.
- `TC-006-status-json-no-pr.runner.md`
  - Validate `ace-git status --format json --no-pr` emits parseable JSON without PR lookup dependency.
- `TC-006-status-json-no-pr.verify.md`
  - Verify JSON output shape includes branch/repository keys and successful execution.

### Proposed Scenario Structure
1. Goal 1: Status baseline (`TC-001`)
2. Goal 2: Diff baseline (`TC-002`)
3. Goal 3: Branch baseline (`TC-003`)
4. Goal 4: PR/fallback behavior (`TC-004`, modified)
5. Goal 5: Diff output-path security (`TC-005`, new)
6. Goal 6: Status JSON/no-pr deterministic mode (`TC-006`, new)

### Execution Notes for Rewrite
- Keep numbering contiguous and update all bundle references.
- Preserve runner/verifier contract: runner executes and captures only, verifier assigns verdicts.
- Avoid introducing new tooling dependencies beyond already-declared scenario tools (`ace-git`, `git`).
