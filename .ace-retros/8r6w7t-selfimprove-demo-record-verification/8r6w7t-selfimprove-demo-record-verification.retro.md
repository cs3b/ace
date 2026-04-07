---
id: 8r6w7t
title: selfimprove-demo-record-verification
type: standard
tags: [self-improvement, process-fix]
created_at: "2026-04-07 21:28:41"
status: active
---

# selfimprove-demo-record-verification

## What Went Well

- Live demo recording exposed real regressions that unit and package tests missed.
- The failure mode was reproducible from the cast and could be traced back to specific product and tape defects.
- The recorder already produced enough artifacts to support a stricter verification layer without redesigning the whole demo pipeline.

## What Could Be Improved

- `ace-demo record` treated command-presence verification as success even when the recorded behavior was wrong.
- Bad recordings could still be uploaded to a PR, which turns a debugging artifact into misleading release evidence.
- There was no standard report path for demo failures, so product bugs and tape bugs had to be diagnosed ad hoc from the cast.

## Action Items

- Keep YAML demo recordings fail-closed: no upload or PR comment when verification is not a true pass.
- Require semantic `verify:` assertions for demos that exercise external systems or multi-step state changes.
- Classify verification failures as `instruction_defect`, `product_bug`, or `verification_error` and write reports to `.ace-local/demo/`.
- When a failure is classified as `instruction_defect`, fix the tape and retry once before escalating.
