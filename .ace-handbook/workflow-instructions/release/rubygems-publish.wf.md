---
name: release-rubygems-publish
allowed-tools: Bash, Read
description: Publish ACE gems to RubyGems.org in dependency order
argument-hint: "[gem-name...] [--dry-run]"
doc-type: workflow
purpose: RubyGems publishing workflow
update:
  frequency: on-change
  last-updated: '2026-08-12'
---

# RubyGems Publish Workflow

## Goal

Publish ACE gems to RubyGems.org in correct dependency order, skipping already-published versions and stopping on first failure.

## Prerequisites

* Repository root contains `ace-*/` gem directories with `.gemspec` files
* Each target gem has a `lib/**/version.rb` with the current version
* RubyGems credentials are configured (`~/.gem/credentials` or `GEM_HOST_API_KEY` env var)
* No version bumping — this workflow publishes versions as they currently exist

## Timing Contract (critical)

RubyGems OTP codes are short-lived (**~30–45 seconds**). The live publish burst must finish inside that window.

Hard sequence:

1. Resolve credentials and pending queue
2. **Build every pending `.gem` artifact**
3. Show the final publish queue
4. **Only then** ask the operator for one OTP
5. Push immediately in dependency-respecting waves of **up to 5 concurrent** `gem push` calls (aim **≤30s** for the whole burst)
6. Verify metadata **after** the burst (never between pushes inside the OTP window)

Never request OTP before builds are complete. Never run slow verification, network discovery, or rebuilds after the OTP is collected.

## Instructions

### 1. Verify Credentials

Check that RubyGems authentication is available:

```bash
[ -f ~/.gem/credentials ] && echo "✓ credentials file found" || echo "✗ no credentials file"
echo "${GEM_HOST_API_KEY:+✓ GEM_HOST_API_KEY is set}"
```

If `GEM_HOST_API_KEY` is unset, try loading project/tooling env without printing secrets (for example `mise env`) and re-check. Do not dump the key value.

If neither credentials file nor `GEM_HOST_API_KEY` exists after that, stop and report:

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

### 5. Build Gems (before OTP)

For each gem that needs publishing (in dependency order):

```bash
cd ace-<name> && gem build ace-<name>.gemspec
```

Rules:

* Run **all** builds before any OTP prompt or `gem push`
* Confirm every pending gem has a local `ace-<name>-X.Y.Z.gem` artifact
* Do **not** ask for OTP in this step

### 6. Validate Plan and Collect OTP

In live mode, only after every artifact exists:

1. Show the final publish queue with order, versions, and artifact paths (and total count)
2. Tell the operator OTP is short-lived (~30–45s) and pushes start immediately
3. Prompt once for the RubyGems OTP
4. If OTP is not provided, abort:

```text
Aborted by operator: no OTP provided.
```

Use the same OTP for the whole burst. If the OTP expires mid-burst, stop, list remaining unpublished gems, ask for a **fresh** OTP, and resume from the first unpublished artifact (rebuild only if an artifact is missing).

### 7. Publish Gems (OTP-critical path)

**Dry-run mode** (`--dry-run`):

```text
[DRY RUN] Would publish:
  Gem:     ace-<name>
  Version: X.Y.Z
  Order:   N of M
  Wave:    W (up to 5 concurrent)
```

**Live mode**:

1. Partition the topo-ordered pending queue into waves where each wave has at most **5** gems and every gem's unpublished ACE runtime dependencies are already published (or already on RubyGems / earlier waves).
2. For each wave, start up to 5 concurrent pushes:

```bash
gem push ace-<name>-X.Y.Z.gem --otp <OTP>
```

3. Wait for the wave to finish before starting the next wave.
4. Aim to complete all waves within ~30 seconds of receiving the OTP.
5. Do **not** run metadata verification, changelog edits, or other slow work between pushes.
6. Clean up each successful artifact after its push returns:

```bash
rm -f ace-<name>/ace-<name>-*.gem
```

**On failure**: Stop immediately. Report which gem failed and why. Do not attempt to publish dependent gems that still need the failed dependency.

```text
✗ Failed to publish ace-<name> X.Y.Z — dependents skipped:
  - ace-dependent-a
  - ace-dependent-b
```

If the failure is an incorrect/expired OTP, request a fresh OTP and resume the remaining queue.

### 8. Report Results

Summarize all actions:

```text
✓ Published ace-support-core 0.5.0
✓ Published ace-bundle 0.12.0
⊘ Skipped ace-git 0.11.0 (already published)
✗ Failed ace-review 0.8.0 — stopped
  Skipped dependents: ace-overseer
```

### 9. Verify Published Metadata (after the burst)

After the full publish burst succeeds (or after a completed resume batch), verify RubyGems recorded publish timestamp and build date for each newly published version:

```bash
curl -fsSL https://rubygems.org/api/v1/versions/ace-<name>.json
curl -fsSL https://rubygems.org/api/v1/gems/ace-<name>.json
```

Check:

* `created_at` matches the actual publish event
* `built_at` is not the RubyGems fallback `1980-01-02T00:00:00.000Z`

If `built_at` falls back to `1980-01-02T00:00:00.000Z`, stop and treat it as a gemspec metadata regression before any further publishes.

RubyGems search-index lag is expected briefly after a burst; prefer the versions API over `gem search` for immediate confirmation.

### 10. Recommended: Verify Installation

After live publishing, run the E2E install verification scenario to confirm gems are installable from RubyGems.org:

```bash
ace-test-e2e ace-monorepo-e2e TS-MONO-001
```

This sets up an isolated sandbox and classifies the install path as `SAFE`, `LAG_DETECTED`, or `METADATA_BROKEN`. See `ace-handbook/docs/release-rubygems-proof.md` for the classification contract.

## Success Criteria

- Gems are published in correct dependency order
- Already-published versions are skipped cleanly
- First non-OTP failure stops the pipeline (dependents would fail anyway)
- No version bumping occurs
- `.gem` build artifacts are cleaned up
- `--dry-run` produces accurate output without side effects
- Credentials are verified before any publish attempt (including `mise`/env loading when needed)
- OTP is collected only after all builds exist, then used in ≤5-wide concurrent waves aimed at ≤30s
- Metadata verification runs after the burst, not between pushes
- After live publishing, recommend running `ace-test-e2e ace-monorepo-e2e TS-MONO-001` to verify installation propagation

## Response Template

**Published:** [count]
**Skipped:** [count] (already on RubyGems)
**Failed:** [count and reasons, if any]
**Mode:** [live|dry-run]
**Waves:** [count × ≤5 concurrent]
**Next Step:** Run `ace-test-e2e ace-monorepo-e2e TS-MONO-001` to verify installation
