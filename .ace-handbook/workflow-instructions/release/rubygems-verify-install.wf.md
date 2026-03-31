---
name: release-rubygems-verify-install
allowed-tools: Bash, Read
description: Verify ACE gem installation from RubyGems.org in an isolated sandbox
argument-hint: "[--ruby <version>]"
doc-type: workflow
purpose: Post-publish RubyGems installation verification
update:
  frequency: on-change
  last-updated: '2026-03-31'
---

# RubyGems Verify Install Workflow

## Goal

Verify that published ACE gems are installable from RubyGems.org in an isolated sandbox environment. Produces a deterministic proof artifact classifying the install path as `SAFE`, `LAG_DETECTED`, or `METADATA_BROKEN`.

## Prerequisites

* ACE gems have been published to RubyGems.org (via `wfi://release/rubygems-publish` or manually)
* `mise` is available on `PATH` for Ruby version management
* Project root `Gemfile` lists ACE gems with `path:` directives (in default and/or grouped sections)

## Instructions

### 1. Discover ACE Gems

Parse the project root `Gemfile` to extract publishable ACE gem names across all sections (including grouped blocks such as `:development, :test`):

```bash
PROJECT_ROOT=$(pwd)
# Extract all ace-* gem declarations regardless of Gemfile group placement
grep "^gem 'ace-" "$PROJECT_ROOT/Gemfile" | sed "s/gem '\\([^']*\\)'.*/\\1/"
```

Record the gem count for the proof artifact.

### 2. Create Sandbox Directory

```bash
PROOF_TIMESTAMP=$(date -u +%Y%m%d%H%M%S)
SANDBOX_DIR=$(mktemp -d /tmp/ace-rubygems-verify-XXXXXXXX)
```

### 3. Set Up Ruby via mise

Match the project's Ruby version in the sandbox:

```bash
PROJECT_RUBY=$(ruby -v | awk '{print $2}')
cd "$SANDBOX_DIR"
mise use ruby@"$PROJECT_RUBY"
mise trust
```

If `--ruby <version>` was provided as an argument, use that version instead.

Verify the sandbox Ruby is active:

```bash
ruby -v
which ruby
```

### 4. Generate Verification Gemfile

Write a Gemfile that installs all ACE gems from RubyGems.org (remote, no `path:` directives):

```bash
{
  echo "source 'https://rubygems.org'"
  echo ""
  grep "^gem 'ace-" "$PROJECT_ROOT/Gemfile" \
    | sed "s/, path:.*//" \
    >> "$SANDBOX_DIR/Gemfile"
}
```

Verify the generated Gemfile lists the expected gem count and contains no `path:` references:

```bash
grep -c "^gem " "$SANDBOX_DIR/Gemfile"
grep "path:" "$SANDBOX_DIR/Gemfile" && echo "ERROR: path directives found" || echo "✓ No path directives"
```

### 5. Run Normal Install Path

```bash
cd "$SANDBOX_DIR"
bundle install 2>&1
NORMAL_EXIT=$?
```

Capture exit status and key output evidence.

### 6. Run Full-Index Fallback

```bash
cd "$SANDBOX_DIR"
bundle install --full-index 2>&1
FULLINDEX_EXIT=$?
```

Capture exit status and key output evidence.

### 7. Classify Result

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

### 8. Store Proof Artifact

Write the proof artifact to the project directory:

```bash
mkdir -p "$PROJECT_ROOT/.ace-local/release"
```

Artifact path:

```text
.ace-local/release/rubygems-proof-YYYYMMDDHHMMSS.md
```

Minimum fields:

* release context (packages verified, gem count, date/time)
* sandbox Ruby version
* normal install result (`bundle install` exit status + evidence)
* full-index result (`bundle install --full-index` exit status + evidence)
* final classification
* operator guidance statement

### 9. Cleanup Sandbox

```bash
rm -rf "$SANDBOX_DIR"
```

If the workflow fails or is interrupted, stale sandbox directories at `/tmp/ace-rubygems-verify-*` may remain. Clean them up manually if needed.

## Success Criteria

- Sandbox is created in a temp directory, not in the project tree
- Ruby version matches the project's Ruby environment (or explicit `--ruby` argument)
- Verification Gemfile lists all ACE gems (including grouped Gemfile sections) as remote dependencies
- Both install paths are attempted and evidence is captured
- Classification is one of: `SAFE`, `LAG_DETECTED`, `METADATA_BROKEN`
- Proof artifact is stored at `.ace-local/release/rubygems-proof-YYYYMMDDHHMMSS.md`
- Sandbox is cleaned up after verification
- `SAFE` is the only classification that permits onboarding-safe claims

## Response Template

**Classification:** [`SAFE` | `LAG_DETECTED` | `METADATA_BROKEN`]
**Proof Artifact:** [.ace-local/release/rubygems-proof-*.md]
**Sandbox Ruby:** [version]
**Gems Verified:** [count]
**Normal Install:** [PASS | FAIL]
**Full-Index Install:** [PASS | FAIL]
