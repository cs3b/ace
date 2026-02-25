# Tag Classification Summary (Task 280.04)

## Scope

Classification applied to 33 E2E scenarios across 11 packages using:
- Group tags: `smoke`, `happy-path`, `deep`
- Domain tags: `use-case:<domain>`

## Package Matrix

| Package | Scenarios | Smoke Anchor(s) | Deep Scenarios | Use-Case Tag |
|---|---:|---|---|---|
| ace-assign | 9 | TS-ASSIGN-001 | TS-ASSIGN-003a, TS-ASSIGN-004, TS-ASSIGN-005, TS-ASSIGN-006 | `use-case:assign` |
| ace-b36ts | 1 | TS-B36TS-001 | — | `use-case:b36ts` |
| ace-bundle | 3 | TS-BUNDLE-001 | — | `use-case:bundle` |
| ace-git-commit | 3 | TS-COMMIT-001 | — | `use-case:commit` |
| ace-lint | 3 | TS-LINT-001 | TS-LINT-003 | `use-case:lint` |
| ace-support-nav | 3 | TS-NAV-001 | — | `use-case:nav` |
| ace-overseer | 2 | TS-OVERSEER-001 | TS-OVERSEER-002 | `use-case:overseer` |
| ace-prompt-prep | 1 | TS-PREP-001 | — | `use-case:prep` |
| ace-review | 3 | TS-REVIEW-001 | TS-REVIEW-005 | `use-case:review` |
| ace-git-secrets | 3 | TS-SECRETS-001 | — | `use-case:secrets` |
| ace-git-worktree | 2 | TS-WORKTREE-001 | TS-WORKTREE-002 | `use-case:worktree` |

## Distribution

- Total scenarios: 33
- Smoke: 11
- Happy-path: 25
- Deep: 8
- Packages missing smoke: none

## Verification Commands

```bash
# All scenarios tagged
rg -n '^tags:' --glob '**/test/e2e/**/scenario.yml' | wc -l

# No package missing a smoke scenario
ruby -ryaml -e 'files=`rg --files -g "**/test/e2e/**/scenario.yml"`.lines.map(&:strip);h=Hash.new(0);files.each{|f|d=YAML.safe_load_file(f,permitted_classes:[Date],aliases:true)||{};h[d["package"]]+=1 if Array(d["tags"]).include?("smoke")};puts h.sort.map{|k,v|"#{k}:#{v}"}'

# Tag filter behavior (execution command supported by runner)
ace-test-e2e suite --tags smoke
ace-test-e2e suite --tags use-case:lint ace-lint
```

## Notes

- `ace-test-e2e-suite` wrapper currently errors in this branch; use `ace-test-e2e suite`.
- `ace-test-e2e suite` does not expose `--dry-run` in current CLI help.
