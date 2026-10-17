---
id: 8x2ysa
title: rubygems-publish-prepare-handoff-gap
type: standard
tags: [release, publishing, handoff]
created_at: "2026-10-03 23:11:27"
status: active
---

# rubygems-publish-prepare-handoff-gap

Date: 2026-10-03
Context: qk1.2 delivery (PR #359, forge-neutral task issue synchronization). The
agent's closure built release gems by hand and reported "ready to publish"; the
Captain's `.ace-bin/ace-rubygems-publish --interactive` then found "nothing to
publish" because it consumed a stale prepared queue from the previous (qk1.1)
burst and scanned a primary checkout that was 129 commits behind the merge.
Author: coding agent (qk1.2 delivery session)
Type: Standard

## What Went Well

- The artifacts themselves were sound: all four gems built, cleanroom-installed
  (empty GEM_HOME, transitives from RubyGems), and load-smoke-tested before
  handoff, so the retry required zero rework — only the correct queue.
- The publisher's two-phase design did its job once used: `--prepare` scanned
  all 50 packages, found everything else already published, built exactly the
  four pending gems in dependency waves, and wrote a fresh manifest.
- Version-collision risk (PR #360 had published ace-git 0.26.0 / github 0.3.0 /
  forgejo 0.4.0 without our changes) was caught before publish by checking
  RubyGems remote versions and rebasing away our redundant version bumps.

## What Could Be Improved

- **The agent skipped `--prepare` entirely.** I hand-rolled `gem build` into the
  task worktree's `.ace-local/gems/` and called it "prepared for publish," never
  loading `as-release-rubygems-publish` or the publisher's own two-phase flow.
  The handoff artifact the operator actually consumes (the prepared queue) was
  never produced.
- **Location mismatch went unchecked.** The publisher is ROOT-anchored to the
  primary checkout (`/Users/mc/Ps/ace`); agent-built artifacts in a worktree's
  `.ace-local/` are invisible to it, and the primary checkout's main only moves
  when someone fast-forwards it — after the merge it sat 129 commits behind,
  so even a queue-less scan would have found nothing pending.
- **The stale manifest silently overrides the scan.** `pending-queue.yml` from
  the qk1.1 burst listed two already-published gems; the tool trusted it
  verbatim and exited with "nothing to publish" instead of flagging that the
  manifest predates the current main ref.
- **No handoff protocol between "agent finishes a release" and "operator
  publishes."** Past pattern was the operator running the whole burst
  interactively; the delivery flow had no step that ends with a *prepared*
  queue, so every delivery re-invents the last mile.

## Key Learnings

- "Prepared for publish" must mean **the publisher's own `--prepare` has run
  from the primary checkout on the merged main** — not "gem artifacts exist
  somewhere." The queue file, not the .gem files, is the handoff contract.
- Caches that override scans (the pending-queue manifest) need staleness
  signals: without one, a consumed-but-not-cleared manifest turns the next
  publish into a confusing no-op.
- Worktree discipline has an operational corollary: anything ROOT-anchored
  (the publisher, `ace-rubygems-needs-release`) sees only the primary
  checkout — after every merge, fast-forward the primary checkout before
  touching release tooling.
- Check RubyGems remote versions before choosing release versions: PR #360 had
  published the exact version numbers our branch had bumped, which would have
  produced un-pushable colliding gems.

## Improvement Proposals

### Process Improvements

- Add to the integration delivery protocol: after merge, sync origin → local
  main → primary checkout, then run
  `.ace-bin/ace-rubygems-publish --prepare` from the primary checkout and hand
  the operator the `--interactive` run. Ad-hoc `gem build` staging is not a
  substitute.
- The release skill (`as-release-rubygems-publish`) should state the
  primary-checkout requirement and the prepare-then-interactive sequence
  explicitly at the top.

### Tool Enhancements

- `ace-rubygems-publish`: record the main ref SHA and manifest `recorded_at`
  in `pending-queue.yml`; on `--interactive`, refuse (or require `--force`) when
  the manifest's ref is not an ancestor of, or equal to, the current HEAD.
- `ace-rubygems-publish`: when the prepared queue yields "nothing to publish,"
  print the manifest's age and the current main SHA so staleness is obvious.
- `ace-rubygems-needs-release` / `--prepare`: warn when HEAD is behind
  `origin/main` before scanning.

## Action Items

### Stop Doing

- Hand-building release gems into worktree `.ace-local/` as a publish handoff.
- Treating "artifacts exist" as "publish is prepared."

### Continue Doing

- Cleanroom install + load smoke test of every built gem before handoff
  (caught nothing this time, but it is the reason retries are cheap).
- Checking RubyGems remote versions before picking release versions.

### Start Doing

- Post-merge release handoff: sync primary checkout → `--prepare` → operator
  runs `--interactive` (record this in the delivery protocol and the publish
  skill).
- Manifest staleness guard in `ace-rubygems-publish` (ref SHA + age check).

## Technical Details

- Stale manifest: `.ace-local/rubygems-publish/pending-queue.yml` held
  ace-review 0.58.1 + ace-assign 0.61.1 from the qk1.1 burst (both published).
- Primary checkout was 129 commits behind origin/main at publish time; the
  four pending gems (ace-git 0.27.0, ace-git-github 0.4.0, ace-git-forgejo
  0.5.0, ace-task 0.39.0) exist only in the merge commit 2cae1345b.
- After fixes: primary ff'd to 2cae1345b, stale manifest deleted,
  `--prepare` rebuilt the queue in 3 dependency waves (ace-git →
  github+forgejo → ace-task); operator reruns `--interactive` for the OTP.
