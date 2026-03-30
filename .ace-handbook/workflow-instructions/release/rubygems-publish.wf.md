---
name: release-rubygems-publish
allowed-tools: Bash, Read
description: Publish ACE gems to RubyGems.org in dependency order
argument-hint: "[gem-name...] [--dry-run]"
doc-type: workflow
purpose: RubyGems publishing workflow
update:
  frequency: on-change
  last-updated: '2026-03-29'
---

# RubyGems Publish Workflow

## Goal

Publish ACE gems to RubyGems.org in correct dependency order, skipping already-published versions and stopping on first failure.

## Prerequisites

* Repository root contains `ace-*/` gem directories with `.gemspec` files
* Each target gem has a `lib/**/version.rb` with the current version
* RubyGems credentials are configured (`~/.gem/credentials` or `GEM_HOST_API_KEY` env var)
* No version bumping — this workflow publishes versions as they currently exist

## Instructions

### 1. Verify Credentials

Check that RubyGems authentication is available:

```bash
[ -f ~/.gem/credentials ] && echo "✓ credentials file found" || echo "✗ no credentials file"
echo "${GEM_HOST_API_KEY:+✓ GEM_HOST_API_KEY is set}"
```

If neither exists, stop and report:

```text
No RubyGems credentials found. Set up ~/.gem/credentials or export GEM_HOST_API_KEY before publishing.
```

### 2. Discover Gems

Find all `ace-*/` directories containing a `.gemspec` file:

```bash
ls ace-*/*.gemspec
```

If explicit gem names were provided as arguments, filter to only those gems. Verify each requested gem exists:

```text
✗ ace-nonexistent has no gemspec — aborting
```

### 3. Build Dependency Graph

For each gem, parse its `.gemspec` for internal `ace-*` dependencies:

```bash
grep "add_dependency.*'ace-" ace-<name>/*.gemspec
grep "add_runtime_dependency.*'ace-" ace-<name>/*.gemspec
```

Build a directed dependency graph and perform topological sort so that dependencies are published before dependents.

If a cycle is detected, stop and report:

```text
Circular dependency detected: ace-a → ace-b → ace-a — aborting
```

### 4. Check Each Gem Version

Determine the pending publish set before building or pushing gems:

1. Read the local version from each discovered gemspec
2. Check remote status:
   * Preferred: if `.ace-bin/ace-rubygems-needs-release` exists, run it once and use its output to identify `new` and `pending` gems
   * Fallback: for each gem in dependency order, check RubyGems with:

```bash
gem search "ace-<name>" --remote --exact --versions
```

Validation:

* `gem search --exact` expects the plain gem name. Do not wrap the name in `^...$`.
* If using the helper script, rely on its single remote snapshot as the source of truth for pending-release discovery.

Decision matrix:

| Remote State | Action |
|---|---|
| Not found on RubyGems | Proceed to publish |
| Found, local version not published | Proceed to publish |
| Found, local version already published | Skip with message |
| Found, different owner | Warn and skip |

### 5. Build Gems

For each gem that needs publishing (in dependency order):

```bash
cd ace-<name> && gem build ace-<name>.gemspec
```

Run all builds before any `gem push` step.

### 6. Validate Plan and Collect OTP

In live mode, before publishing:

1. Show the final publish queue with order and artifact names.
2. Prompt once for the RubyGems OTP.
3. If OTP is not provided, abort:

```text
Aborted by operator: no OTP provided.
```

Use the same OTP for all publishes.

### 7. Publish Gems

**Dry-run mode** (`--dry-run`):

```text
[DRY RUN] Would publish:
  Gem:     ace-<name>
  Version: X.Y.Z
  Order:   N of M
```

**Live mode**:

Publish each pre-built gem artifact in order:

```bash
cd ace-<name> && gem push ace-<name>-X.Y.Z.gem --otp <OTP>
```

Clean up after each publish:

```bash
rm -f ace-<name>/ace-<name>-*.gem
```

**On failure**: Stop immediately. Report which gem failed and why. Do not attempt to publish dependent gems.

```text
✗ Failed to publish ace-<name> X.Y.Z — dependents skipped:
  - ace-dependent-a
  - ace-dependent-b
```

### 8. Report Results

Summarize all actions:

```text
✓ Published ace-support-core 0.5.0
✓ Published ace-bundle 0.12.0
⊘ Skipped ace-git 0.11.0 (already published)
✗ Failed ace-review 0.8.0 — stopped
  Skipped dependents: ace-overseer
```

### 9. Verify Published Metadata

After each successful live publish, verify that RubyGems recorded both the publish timestamp and the gem build date:

```bash
curl -fsSL https://rubygems.org/api/v1/versions/ace-<name>.json
curl -fsSL https://rubygems.org/api/v1/gems/ace-<name>.json
```

Check the newly published version entry and confirm:

* `created_at` matches the actual publish event
* `built_at` is not the RubyGems fallback `1980-01-02T00:00:00.000Z`

If `built_at` falls back to `1980-01-02T00:00:00.000Z`, stop and treat it as a gemspec metadata regression before publishing more packages.

### 10. Run Post-Publish Dependency Propagation Proof

After live publishing finishes, run one deterministic install proof for the full ACE stack install path:

```bash
bundle install
bundle install --full-index
```

Scope and evidence rules:

* This proof is for multi-package release propagation, not single-gem smoke checks.
* Capture command exit status plus key stderr/stdout snippets for both attempts.
* Store proof output in one artifact for downstream docs and release audit:

```text
.ace-local/release/rubygems-proof-YYYYMMDDHHMMSS.md
```

Classification contract (required):

| Signal | Classification | Required operator statement |
|---|---|---|
| `bundle install` succeeds | `SAFE` | Normal install path is safe. |
| `bundle install` fails, `bundle install --full-index` succeeds | `LAG_DETECTED` | RubyGems metadata lag detected; use `bundle install --full-index` until registry propagation catches up. |
| Neither path succeeds, or evidence cannot distinguish lag vs metadata defect | `METADATA_BROKEN` | Release is not onboarding-safe; investigate ACE metadata before declaring install stability. |

Decision guard:

* Do not collapse `LAG_DETECTED` and `METADATA_BROKEN` into one generic failure.
* If the distinction is unclear from evidence, classify as `METADATA_BROKEN` and stop.
* Do not claim onboarding-safe status unless classification is `SAFE`.

## Success Criteria

- Gems are published in correct dependency order
- Already-published versions are skipped cleanly
- First failure stops the pipeline (dependents would fail anyway)
- No version bumping occurs
- `.gem` build artifacts are cleaned up
- `--dry-run` produces accurate output without side effects
- Credentials are verified before any publish attempt
- Live mode gathers publish plan then collects OTP once and reuses it for every `gem push`
- Live mode verifies RubyGems `created_at` and `built_at` for each newly published version
- Live mode produces one proof artifact with required classification: `SAFE`, `LAG_DETECTED`, or `METADATA_BROKEN`
- `SAFE` is the only classification that permits onboarding-safe release claims

## Response Template

**Published:** [count]
**Skipped:** [count] (already on RubyGems)
**Failed:** [count and reasons, if any]
**Mode:** [live|dry-run]
**Propagation Proof:** [`SAFE` | `LAG_DETECTED` | `METADATA_BROKEN`]
**Proof Artifact:** [.ace-local/release/rubygems-proof-*.md or N/A in dry-run]
