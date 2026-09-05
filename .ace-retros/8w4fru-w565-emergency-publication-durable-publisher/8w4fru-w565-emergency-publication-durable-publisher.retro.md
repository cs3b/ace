---
id: 8w4fru
title: w565-emergency-publication-durable-publisher
type: standard
tags: [release, rubygems, security]
created_at: "2026-09-05 10:30:57"
status: active
---

# w565-emergency-publication-durable-publisher

## What Went Well

- W565 completed the emergency 38-gem publication and exposed the build-before-OTP timing constraint.

- Existing single-snapshot discovery and dependency metadata provided a sound base for safe scheduling and resume.

## What Could Be Improved

- The emergency process depended on prose and an untracked script, so its safety contract lacked regression tests.

- Positional OTPs were visible in process arguments, and broad child-output reporting could echo a secret.

- Worktree paths are environment-specific; repair commands are unsafe when visible and host paths differ.

## Key Learnings

- Secret handling is an interface property: reject positional OTPs and let RubyGems read its environment directly.

- Resume safety needs a fresh remote snapshot and artifact proof: delete confirmed publications and retain the rest.

- A credential-free dry-run is the safest public planning and review surface.

## Action Items

- [x] Replace the W565 seed with a tracked publisher and focused secret-boundary tests.

- [x] Cover dependency waves, preflight failures, build ordering, cleanup, and resume behavior.

- [x] Point the ACE release workflow at the publisher and document a non-secret HITL readiness handoff.

- [ ] Record exact test, commit, tree, and Forgejo PR evidence in task `8w4.t.frh`.
