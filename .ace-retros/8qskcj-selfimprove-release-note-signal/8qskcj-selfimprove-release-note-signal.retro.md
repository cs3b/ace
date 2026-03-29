---
id: 8qskcj
title: selfimprove-release-note-signal
type: self-improvement
tags: [process-fix]
created_at: "2026-03-29 13:33:56"
status: active
---

# selfimprove-release-note-signal

## What Went Well
- The release workflows already distinguished follower packages at the versioning level, so the structural signal needed for a presentation fix was available.
- The current `v0.9.934` release could be repaired without changing package-level release metadata.

## What Could Be Improved
- Root changelog guidance treated primary release changes and dependency-follower fallout with the same prominence.
- GitHub release package grouping lacked a mixed-release rule for compressing follower-only dependency updates into a short technical summary.
- The resulting `v0.9.934` release buried the main `ace-git` change under a long list of follower package bullets.

## Action Items
- Updated `wfi://release/publish` to tell agents to present primary changes first and collapse follower-only dependency fallout into a compact technical block.
- Updated `wfi://github/release-publish` to preserve a trailing `Technical side effects` section for mixed releases instead of exploding follower packages into full package blocks.
- Rewrote the current `CHANGELOG.md` `0.9.934` entry and the live GitHub release body so `ace-git` and `ace-handbook` lead, with follower packages summarized compactly.
