## E2E Coverage Review: ace-git
**Reviewed:** 2026-03-20T23:01:35Z  
**Scope:** package-wide  
**Workflow version:** 2.1

### Summary
| Metric | Count |
|--------|-------|
| Package features | 6 |
| Unit test files | 35 |
| Unit assertions (command-surface subset) | 106 |
| E2E scenarios | 1 |
| E2E test cases | 4 |
| TCs with decision evidence | 4/4 |

### Feature Inventory
| Feature | Command | External Tools | Description |
|--------|---------|----------------|-------------|
| Repository context summary | `ace-git status` | `git`, optional `gh` | Branch/state/PR activity summary (`--format`, `--no-pr`, `--commits`) |
| Status with PR diff block | `ace-git status --with-diff` | `gh` | Appends PR diff when PR metadata is available |
| Repository diff generation | `ace-git diff` | `git` | Range/since/path-filtered diff generation |
| Secure diff output-path handling | `ace-git diff --output` | filesystem | Validates output path against traversal and allowed roots |
| Branch metadata rendering | `ace-git branch` | `git` | Text/JSON branch + tracking state |
| PR metadata retrieval | `ace-git pr` | `gh` | Direct/auto PR metadata and optional diff |

### Coverage Matrix
| Feature | Unit Tests | E2E Tests | Status |
|--------|------------|-----------|--------|
| Repository context summary (`status`) | `test/commands/status_test.rb` | `TC-001-git-status` | Covered |
| Diff output for working tree changes | `test/commands/diff_test.rb` | `TC-002-git-diff` | Covered |
| Branch info rendering | `test/commands/branch_test.rb` | `TC-003-branch-info` | Covered |
| PR-context command behavior | `test/commands/pr_test.rb`, `test/commands/status_test.rb` | `TC-004-pr-summary` | Covered |
| Secure output-path rejection for diff (`--output`) | `test/commands/diff_test.rb` | none | Unit-only |
| Status JSON and `--no-pr` behavior on real repo | `test/commands/status_test.rb` | none | Unit-only |

### Overlap Analysis
TCs with overlap against unit tests are still E2E-valuable because they validate real repository and CLI wiring:

| TC ID | Feature | Overlapping Unit Tests | Recommendation |
|------|---------|------------------------|----------------|
| TC-001 | status | `test/commands/status_test.rb` | Keep — validates real git repo state in sandbox |
| TC-002 | diff | `test/commands/diff_test.rb` | Keep — validates end-to-end real working-tree mutation |
| TC-003 | branch | `test/commands/branch_test.rb` | Keep — validates branch state in initialized sandbox |
| TC-004 | pr/status fallback | `test/commands/pr_test.rb` | Modify — strengthen deterministic fallback assertions |

**Candidates for removal:** 0

### E2E Decision Record Coverage
| TC ID | Evidence Status | Missing Fields |
|------|------------------|----------------|
| TS-GIT-001 | complete | none |

### Gap Analysis
| Feature | External Tools | Unit Coverage | E2E Needed? |
|--------|----------------|---------------|-------------|
| `diff --output` path safety | filesystem | yes | yes — add one CLI-path rejection TC to validate real command behavior |
| status JSON + no-pr mode in real repo | git | yes | yes — add one TC that verifies JSON shape without network/PR dependency |

### Health Status
| TC ID | Last Verified | Status |
|------|---------------|--------|
| TC-001 | not recorded | Never verified |
| TC-002 | not recorded | Never verified |
| TC-003 | not recorded | Never verified |
| TC-004 | not recorded | Never verified |

**Outdated (>30 days):** 0  
**Never verified:** 4

### Consolidation Opportunities
No high-value consolidation identified; current four-TC split matches command surface and keeps diagnostics local.

### Recommendations
1. Add a deterministic TC for `ace-git diff --output` path rejection to cover CLI security behavior under real execution.
2. Add a deterministic TC for `ace-git status --format json --no-pr` to lock JSON/no-network behavior.
3. Tighten TC-004 verification language to explicitly accept either PR metadata or explicit no-PR fallback evidence.

### Next Step
Run Stage 2 planning using this report to produce a concrete KEEP/MODIFY/REMOVE/CONSOLIDATE/ADD change plan.
