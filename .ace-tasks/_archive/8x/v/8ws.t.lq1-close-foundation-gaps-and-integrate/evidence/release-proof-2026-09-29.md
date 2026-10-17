# RubyGems Propagation Proof — 2026-09-29 13-gem release

- Proof timestamp: 2026-09-29 14:44:51 (WEST)
- Released today (operator-run `--interactive` live burst, 12.6s, 6 waves × ≤5):
  ace-support-test-helpers 0.14.6, ace-test 0.7.4, ace-git 0.25.0, ace-lab 0.1.0,
  ace-runtime 0.1.0, ace-git-forgejo 0.2.0, ace-git-github 0.2.0, ace-handbook 0.33.0,
  ace-test-runner 0.27.0, ace-handbook-integration-pi 0.5.0, ace-assign 0.58.0,
  ace-git-worktree 0.24.0, ace-overseer 0.17.0

## Normal install (`bundle install`)

- Result: SUCCESS (exit 0)
- Evidence: `.ace-local/test-e2e/8wskfgw-monorepo-e2e-ts001/results/tc/02/install.stdout`
  → `Bundle complete! 48 Gemfile dependencies, 73 gems now installed.`
- Isolated proof contract: `env -i` + sandbox-ruby bundler, confined GEM/BUNDLE paths
  (TC-002 scenario contract), fresh lockfile, 48 ACE gems in `bundle list`.
- Lockfile check: resolves ace-support-test-helpers 0.14.6, ace-git 0.25.0, ace-lab 0.1.0,
  ace-runtime 0.1.0, ace-git-forgejo 0.2.0, ace-handbook 0.33.0, ace-test-runner 0.27.0,
  ace-handbook-integration-pi 0.5.0, ace-assign 0.58.0, ace-git-worktree 0.24.0,
  ace-overseer 0.17.0.

## Full-index install (`bundle install --full-index`)

- Result: SUCCESS (exit 0, not needed as fallback)
- Evidence: `.ace-local/test-e2e/8wskfgw-monorepo-e2e-ts001/results/tc/03/fullindex.stdout`
  → `Bundle complete! 48 Gemfile dependencies, 73 gems now installed.`

## Direct-install spot proofs (constraint-limited cases)

- `gem install ace-git-github -v 0.2.0` → Successfully installed (6 gems with deps)
- `gem install ace-test -v 0.7.4` → Successfully installed

## Final classification

**SAFE** — the normal install path succeeds from a clean, isolated surface against
RubyGems.org. Onboarding-safe release statement is valid.

## Caveats (documented, non-blocking)

1. `ace-git-github 0.2.0` is published but constraint-unreachable via dependency
   resolution: published ace-bundle 0.44.1 / ace-review 0.56.0 / ace-task 0.38.0
   gemspecs still pin `~> 0.1.1` (their `~> 0.2` constraint edits landed in source
   without version bumps). Resolution lands on the consistent, working 0.1.2 set.
   0.2.0 becomes reachable when those gems republish. Direct install of 0.2.0 works.
2. The scenario's gem-discovery grep missed the indented `ace-test` line in the root
   Gemfile (line-anchor bug, fixed in scenario.yml this session), so ace-test 0.7.4
   was verified by direct install rather than the lockfile.

## Operator guidance statement

Normal install path is safe. No `--full-index` mitigation required.

## Known runner issue (not a registry problem)

The ace-llm codex wrapper declares "timeout" and falls back when a runner session
spans >~230s — both verification runs show codex completing all four goals verbatim
with successful installs, then the wrapper dropping the session during the idle
window of long `bundle install` commands (suspected idle stream drop at the codex
transport layer, misclassified by `ErrorClassifier` because the stderr contains
"timeout"). Fallback chain on this Mac is fully dead (gemini CLI IneligibleTierError,
claude >10MB stdin limit, zai missing 'ro' preset). File as ace-llm/ace-test-runner-e2e
follow-up; does not affect the classification above, which rests on the captured
install evidence.
