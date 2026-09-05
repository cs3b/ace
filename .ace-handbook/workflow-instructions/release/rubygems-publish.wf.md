---
name: release-rubygems-publish
allowed-tools: Bash, Read
description: Publish ACE gems to RubyGems.org in dependency order
argument-hint: "[gem-name...] [--dry-run|--prepare]"
doc-type: workflow
purpose: RubyGems publishing workflow
update:
  frequency: on-change
  last-updated: "2026-09-05"
---

# RubyGems Publish Workflow

## Goal

Publish pending ACE gems through the repository's tested publisher. The
publisher uses one remote snapshot, dependency-safe waves of at most five
pushes, build-before-OTP preparation, and artifact-preserving resume behavior.

This workflow never bumps versions, creates releases, or publishes in dry-run
or prepare mode.

## Public Planning

Dry-run needs no credential or OTP and performs no build or registry mutation:

```bash
.ace-bin/ace-rubygems-publish --dry-run [gem-name...]
```

Review the reported versions, artifact paths, and waves. Requested gems include
their pending internal runtime dependencies. Unknown gems and dependency cycles
fail before any build.

## Credential and Build Preparation

Configure RubyGems authentication through `GEM_HOST_API_KEY` or the standard
RubyGems credentials file without printing or reading the credential value.
Then prepare every artifact:

```bash
.ace-bin/ace-rubygems-publish --prepare [gem-name...]
```

Prepare mode asks RubyGems to validate the configured credential, refreshes the
pending snapshot, and builds every missing artifact. It does not require an OTP
and never calls `gem push`. A failure stops before publication and retains all
artifacts.

## OTP HITL Handoff

Only after prepare succeeds, create a canonical human-attention event:

```bash
ace-hitl create "RubyGems OTP environment ready" \
  --kind approval \
  --question "Configure a fresh GEM_HOST_OTP_CODE in the publisher process environment, then answer ready. Do not include the OTP in this answer." \
  --tags release,rubygems,security \
  --resume "/as-release-rubygems-publish"
```

The operator's persisted HITL answer is readiness only. Never put an OTP in an
HITL title, question, answer, task, report, command argument, shell trace, or
chat transcript. The operator configures `GEM_HOST_OTP_CODE` through the
approved secret environment outside the logged command surface.

## Live Publish

After the operator confirms readiness, run the publisher without a mode flag:

```bash
.ace-bin/ace-rubygems-publish [gem-name...]
```

The publisher:

1. Revalidates the credential without exposing it.
2. Refreshes the remote version snapshot and skips versions already published.
3. Reuses prepared artifacts and builds only missing artifacts.
4. Validates that `GEM_HOST_OTP_CODE` has the expected shape.
5. Starts `gem push` in deterministic dependency waves of at most five.

RubyGems reads `GEM_HOST_OTP_CODE` directly from the inherited environment.
The publisher never copies it into argv, output, errors, or reports. All
non-push subprocesses run with that variable removed.

## Failure and Resume

The publisher waits for the current wave and stops before later waves when any
push fails. It removes only artifacts whose RubyGems result proves publication
or prior publication. Failed and not-yet-attempted artifacts remain on disk.

For an OTP rejection or partial release:

1. Review the generic failure and retained-artifact list; no secret is emitted.
2. Configure a fresh OTP through the approved secret environment.
3. Rerun the same live command.

The fresh remote snapshot skips successful versions, and retained artifacts are
reused for the remaining queue.

## Post-Publish Verification

After the complete burst succeeds, verify RubyGems metadata outside the OTP
window and run the repository propagation proof:

```bash
ace-test-e2e ace-monorepo-e2e TS-MONO-001
```

Use `ace-handbook/docs/release-rubygems-proof.md` to classify the result as
`SAFE`, `LAG_DETECTED`, or `METADATA_BROKEN`. Do not claim onboarding safety
without this proof.

## Success Criteria

- The dry-run is credential-free and non-mutating.
- Every build finishes before the first OTP-consuming push.
- Credentials and OTP shape are validated before publication.
- Dependency waves are deterministic and contain no more than five pushes.
- Already-published versions are skipped from a fresh remote snapshot.
- Partial releases resume without rebuilding retained artifacts.
- Only proven-published artifacts are removed.
- Credential and OTP values never enter argv, output, reports, fixtures, or HITL records.
