## E2E Coverage Review: ace-git-secrets

Reviewed: 2026-03-18
Scope: package-wide (`TS-SECRETS-001`)
Workflow version: 2.1

### Summary

| Metric | Count |
|--------|-------|
| Package features | 8 |
| Unit test files | 13 |
| E2E scenarios | 1 |
| E2E test cases | 7 |

### Coverage Matrix

| Feature | Unit Tests | E2E Tests | Status |
|---------|------------|-----------|--------|
| CLI discovery/help/version | `test/commands/cli_test.rb` | TC-001 | Overlap |
| Secret detection exit behavior | `test/commands/cli_test.rb`, `test/molecules/history_scanner_test.rb` | TC-002, TC-003 | Covered |
| History persistence after file deletion | scanner + git rewrite units | TC-003 | E2E-value |
| JSON report and whitelist behavior | `history_scanner_test.rb`, `security_auditor_test.rb`, `cli_test.rb` | TC-004 | Covered |
| Rewrite dry-run behavior | `rewrite_command_test.rb`, `history_cleaner_test.rb`, `git_rewriter_test.rb` | TC-005 | Covered |
| Error handling when `raw_value` missing | `rewrite_command_test.rb`, `revoke_command_test.rb` | TC-006 | Covered |
| Config cascade and override behavior | scanner/config-related unit tests | TC-007 | Covered |
| Pre-release release gate (`check-release`) | `cli_test.rb`, `release_gate_test.rb`, `check_release_command.rb` | none | Gap |

### Overlap Analysis

- TC-001 provides onboarding/discovery value, but has strong unit overlap with `test/commands/cli_test.rb` help/version coverage.
- It should be retained only as lightweight discovery context for runner behavior, not as deep assertion-heavy validation.

### Gap Analysis

- No E2E currently exercises `ace-git-secrets check-release`, even though it is user-facing and release-critical.
- This behavior has genuine E2E value because it binds real CLI invocation + scanner output + CI-facing exit semantics.

### Recommendation

1. KEEP existing 7 TCs with targeted improvements only.
2. ADD a new TC for `check-release` table/json and strict mode behavior.
3. Update scenario manifests to include the new TC and maintain deterministic artifact locations.
