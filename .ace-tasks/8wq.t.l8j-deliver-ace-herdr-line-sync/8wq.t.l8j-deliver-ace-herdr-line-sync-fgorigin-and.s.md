---
id: 8wq.t.l8j
status: pending
priority: high
created_at: "2026-09-27 14:09:30"
estimate: TBD
dependencies: [8wm.t.vs0]
tags: [release, ace-herdr, deploy, rubygems]
bundle:
  presets: [project]
  files:
    - ace-herdr/CHANGELOG.md
    - ace-herdr/ace-herdr.gemspec
  commands: []
---

# Deliver ace-herdr line: sync fg/origin and publish ace-herdr 0.1.0

## Kontekst

8wm.t.vs0 (ace-herdr: push delivery + agent bootstrap) is DONE locally:
implementation reviewed clean (codex, 0 findings), 79 tests green, but the
delivery tail was split out per Captain's decision (2026-09-27): "mark done —
deploy is different task". This task owns that tail.

## Zakres (behavioral)

1. **Sync fg (source of truth)**: local `main` is ahead of `fg/main` by a
   25-commit range that includes the entire ace-herdr implementation
   (`a8f9d320c..e90c2c2e4`), task-store work, and the k84/k86 spec drafts.
   Push `main` → `fg/main`. Merge gate per policy: executed tests + reviewer
   verdict — both satisfied for vs0; CI advisory.
2. **Mirror origin**: push `main` → `origin/main` (bypass-protected; 4
   commits behind at draft time — will be more after the fg push).
3. **Publish ace-herdr 0.1.0** via the tested publisher (as-release
   pipeline, operator --interactive as used for the 11-gem sweep).
   Pre-publish: squash CHANGELOG `[Unreleased]` into `0.1.0 - 2026-09-27`.
4. **Post-publish proof**: cleanroom install check (clean ruby, empty
   GEM_HOME, pinned Gemfile; `--full-index` if CDN lag — see PR#339
   precedent LAG_DETECTED) + proof artifact under `.ace-local/`.

## Kryteria sukcesu

- [ ] `git log fg/main..main` empty; `git log origin/main..main` empty.
- [ ] `gem list -r ace-herdr` (or install proof) shows 0.1.0.
- [ ] CHANGELOG has no `[Unreleased]` block; version 0.1.0 dated.
- [ ] Proof artifact recorded (safe / lag-detected + --full-index pass).

## Out of scope

- ace-hitl 0.10.x republish, hermes, or any other gem (already published).
- The k84/k86 implementation work (specs only so far; separate tasks).
- Live-herdr e2e (declared follow-up of vs0).

## References

- 8wm.t.vs0 (done, archived) — the implemented line being delivered
- Release precedent: PR #339 sweep + rubygems-proof-20260927112200.md
