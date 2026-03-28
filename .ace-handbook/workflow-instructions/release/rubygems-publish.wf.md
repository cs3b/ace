---
name: release-rubygems-publish
allowed-tools: Bash, Read
description: Publish ACE gems to RubyGems.org in dependency order
argument-hint: "[gem-name...] [--dry-run]"
doc-type: workflow
purpose: RubyGems publishing workflow
update:
  frequency: on-change
  last-updated: '2026-03-21'
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
   * Preferred: if `bin/ace-rubygems-needs-release` exists, run it once and use its output to identify `new` and `pending` gems
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

### 5. Publish Gems

For each gem that needs publishing (in dependency order):

**Dry-run mode** (`--dry-run`):

```text
[DRY RUN] Would publish:
  Gem:     ace-<name>
  Version: X.Y.Z
  Order:   N of M
```

**Live mode**:

Build the gem:

```bash
cd ace-<name> && gem build ace-<name>.gemspec
```

Publish:

```bash
cd ace-<name> && gem push ace-<name>-X.Y.Z.gem
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

### 6. Report Results

Summarize all actions:

```text
✓ Published ace-support-core 0.5.0
✓ Published ace-bundle 0.12.0
⊘ Skipped ace-git 0.11.0 (already published)
✗ Failed ace-review 0.8.0 — stopped
  Skipped dependents: ace-overseer
```

## Success Criteria

- Gems are published in correct dependency order
- Already-published versions are skipped cleanly
- First failure stops the pipeline (dependents would fail anyway)
- No version bumping occurs
- `.gem` build artifacts are cleaned up
- `--dry-run` produces accurate output without side effects
- Credentials are verified before any publish attempt

## Response Template

**Published:** [count]
**Skipped:** [count] (already on RubyGems)
**Failed:** [count and reasons, if any]
**Mode:** [live|dry-run]
