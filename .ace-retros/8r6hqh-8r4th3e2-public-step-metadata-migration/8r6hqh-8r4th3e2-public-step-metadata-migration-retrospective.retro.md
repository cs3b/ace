---
id: 8r6hqh
title: 8r4.t.h3e.2 public step metadata migration retrospective
type: standard
tags: [ace-assign, skills, metadata, migration, release]
created_at: "2026-04-07 11:49:25"
status: active
---

# 8r4.t.h3e.2 public step metadata migration retrospective

## What Went Well
- Completed the full public-step migration scope end-to-end in one subtree run, including skill metadata migration, resolver changes, compatibility shims, tests, and coordinated release/version updates.
- Preserved runtime behavior by keeping YAML compatibility shims for public steps while moving long-term metadata ownership into canonical skills.
- Caught and corrected downstream expectation drift in `ace-assign/test/atoms/catalog_loader_test.rb` during subtree verification before finalizing.
- Completed required RubyGems propagation proof (`TS-MONO-001`) with `SAFE` classification in the same run.

## What Could Be Improved
- `ace-task plan --content` remains prone to stalled output in this environment; path mode is reliable and should remain the default retrieval path.
- `ace-lint` schema validation for skill `assign.steps` is behind the runtime contract and currently reports intentional migration fields as unknown.
- The release workflow text still references `ace-test-e2e ... --test-id`, while the current CLI expects positional test ID syntax.

## Action Items
- Add/track follow-up to align lint skill schema validation with canonical `assign.steps` metadata ownership.
- Update release workflow wording/examples to the current `ace-test-e2e PACKAGE TEST_ID` CLI signature.
- Keep verify-test stage discipline of rerunning full modified-package profile suites after any recovery fixes, even when targeted tests pass first.
