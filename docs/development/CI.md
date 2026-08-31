# Continuous integration

ACE uses Forgejo Actions for the canonical protected-branch test contract.
The workflow is [`.forgejo/workflows/test.yml`](../../.forgejo/workflows/test.yml).

## Execution strategy

The complete deterministic suite runs in one clean Ruby environment with at
most three package processes. This is deliberate: the repository's 43-package
suite normally completes in about ten seconds on a development workstation,
while one environment per package repeated checkout, system setup, dependency
installation, and native compilation 43 times. The shared Forgejo runner has
three execution slots; higher package concurrency adds CPU contention and can
turn a healthy package into a 30-second timeout.

The single suite environment still preserves package-level evidence. The
repository's `ace-test-suite` process runs packages in parallel and writes one
report tree with the failing package names, output, and summaries. A separate
small `Test Summary` job remains the stable protected-branch check.

The workflow executes all of these contracts:

1. `.ace-bin/ci_package_inventory.rb` validates that the suite contains every
   registered test package exactly once.
2. `ace-test-suite --no-color` runs the complete deterministic package suite.
3. `ace-test-e2e ace-monorepo-e2e --dry-run` validates monorepo E2E discovery
   without invoking an agent provider.
4. `ace-test ace-handbook all` keeps the explicit handbook projection gate.
5. `Test Summary` reports the combined result under the protected context
   `Test Suite / Test Summary (pull_request)`.

## Dependency reuse and trust

The workflow computes a compatibility fingerprint from the repository, exact
`Gemfile.lock`, Ruby engine/version/ABI/platform, and runner image. A warm run
uses the compatible `vendor/bundle` cache only after `bundle check` succeeds.
Missing or corrupt content is reported as `cold-owner` or `invalidated` and is
rebuilt once in the suite environment.

Cache publication is trust-scoped:

- `main` publishes and consumes the protected `main` key;
- a pull request may restore a compatible `main` result but saves only under
  its own untrusted PR scope;
- `main` never restores a PR cache.

Cancelled or failed jobs do not publish their post-job cache. Dependency
outcome, the short fingerprint, Bundler identity, suite timing, package logs,
and reports are retained as non-secret run evidence for seven days.

## Local development

```bash
# Complete deterministic suite (recommended)
ace-test-suite

# Pipe-friendly output matching CI
ace-test-suite --no-color --parallel 3

# One package
ace-test ace-support-core all

# Monorepo E2E discovery without an agent provider
ace-test-e2e ace-monorepo-e2e --dry-run

# Inventory contract used by CI
ruby .ace-bin/ci_package_inventory.rb
```

## Triggers

Tests run for pushes to `main`, pull requests targeting `main`, and manual
workflow dispatches.

## Adding a package

Add the package to `.ace/test/suite.yml`, including its path, group, and
priority. Then run:

```bash
ruby .ace-bin/ci_package_inventory.rb
ace-test-suite --no-color
```

Do not add a package-specific Actions job. Failure localization belongs to the
suite reports rather than a dedicated dependency environment.

## Debugging

1. Open the `Complete package suite` log and identify the failed package.
2. Download `ace-test-evidence-<SHA>` for the suite log and package reports.
3. Reproduce with `ace-test <package> all` or the complete suite.
4. If setup failed, inspect `.ace-local/ci/dependencies.txt`,
   `bundle-check.txt`, and `bundle-time.txt` before changing test topology.
