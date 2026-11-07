---
description: "Autonomous recovery and isolated lease lifecycle: verifier"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-duplicate-restart.verify.md
    - ./TC-002-execution-failures.verify.md
    - ./TC-003-local-hitl.verify.md
    - ./TC-004-lease-failures.verify.md
---

# Autonomous recovery and isolated lease lifecycle

Read `results/setup/fixture.json` for this exact VM/run and source path. The
source's `ace-monorepo-e2e/lab-vm/README.md` documents host instrumentation.
This is a disposable UTM fixture using only local Forgejo.

Inspect final VM/Forgejo/project state first, then owner/native records and
actual command captures. A test is not passed by a model statement, a launch,
a synthetic component probe or a task marked done alone. Missing evidence is
FAIL. Never infer acceptance from artifact existence. Check source SHA, manifest
hash and native artifact provenance against the setup receipt. Render a verdict
and cite concrete evidence for each case, then the passed/total count.
Use exactly one parser-compatible section per case, numbered in order:

```markdown
## Goal 1 — Case title
**Verdict**: PASS or FAIL
**Category**: failure category when applicable
**Evidence**: specific records and values
```

Use one literal verdict token. Include every case even when a prerequisite
fails or the runner did not reach the case.
