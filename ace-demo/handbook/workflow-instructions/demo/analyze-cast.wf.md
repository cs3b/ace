---
doc-type: workflow
title: Analyze Demo Cast Workflow
purpose: cast verification triage workflow instruction
ace-docs:
  last-updated: 2026-04-15
  last-checked: 2026-04-15
---

# Analyze Demo Cast Workflow

## Purpose

Analyze a recorded `.cast` after demo verification fails, decide whether the problem is the recording scenario, the product, or the verification tooling, and route to the correct next workflow before re-recording.

## Instructions

1. Run cast verification:

   ```bash
   ace-demo verify <cast-file> --tape <tape-ref-or-path>
   ```

   If the failed recording preserved a sandbox and the tape uses `assert_commands`, include it:

   ```bash
   ace-demo verify <cast-file> --tape <tape-ref-or-path> --sandbox-path <sandbox-path>
   ```

2. Read the generated report under `.ace-local/demo/` or the selected `--report-dir`.

3. Route by classification:

   - `scenario_defect`:
     - fix the tape, camera/viewpoint, setup, or `verify:` contract
     - keep the product code unchanged
     - re-record after updating the demo scenario
   - `product_bug`:
     - treat the cast as a real product/runtime failure
     - run the normal bug analysis/fix workflow for the affected package
     - re-record only after the product fix lands
   - `verification_error`:
     - fix the verifier, cast parser, tape metadata, or recorder/tooling problem
     - re-run verification
     - re-record only if the original cast is unusable or no longer representative

4. Do not upload or comment on a PR until `ace-demo verify` returns `pass`.

## Success Criteria

- Every failed demo recording is triaged through `ace-demo verify`
- The next action is unambiguous: scenario fix, product bug fix, or verifier/tooling fix
- Re-recording happens only after the correct upstream issue is fixed
