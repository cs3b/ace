---
doc-type: user
title: RubyGems Propagation Proof Contract
purpose: Define deterministic post-release proof for dependency metadata propagation
ace-docs:
  last-updated: 2026-03-29
  last-checked: 2026-03-29
---

# RubyGems Propagation Proof Contract

## Goal

Define one reproducible post-release proof for ACE multi-package publishes that classifies the install path as one of:

- `SAFE`
- `LAG_DETECTED`
- `METADATA_BROKEN`

This contract does not claim to fix RubyGems propagation behavior. It proves whether onboarding-safe install claims are valid at release time.

## Scope

- Applies to many-package ACE releases.
- Runs after publish succeeds, via `ace-test-e2e ace-monorepo-e2e --test-id TS-MONO-001`.
- Produces one artifact consumed by release and onboarding docs workflows.

## Proof Commands

Run in order:

```bash
bundle install
bundle install --full-index
```

Capture for each command:

- exit status
- concise error/output evidence
- timestamp

## Required Artifact

Write one proof artifact:

```text
.ace-local/release/rubygems-proof-YYYYMMDDHHMMSS.md
```

Minimum fields:

- release context (packages/versions, date/time)
- normal install result (`bundle install`)
- full-index result (`bundle install --full-index`)
- final classification
- operator guidance statement

## Decision Matrix

| Observed behavior | Classification | Operator guidance |
| --- | --- | --- |
| Normal install succeeds | `SAFE` | Normal install path is safe. |
| Normal install fails and full-index succeeds | `LAG_DETECTED` | RubyGems metadata lag detected. Use `bundle install --full-index` until propagation catches up. |
| Neither path succeeds, or evidence is ambiguous | `METADATA_BROKEN` | Do not claim onboarding-safe release. Investigate ACE metadata/release correctness first. |

## Guardrails

- Never merge `LAG_DETECTED` and `METADATA_BROKEN` into a single generic failure class.
- If evidence cannot clearly separate registry lag from metadata defects, classify as `METADATA_BROKEN`.
- Only `SAFE` allows onboarding-safe release statements.
- `LAG_DETECTED` is a valid release outcome only when mitigation is explicitly documented.

## Downstream Handoff

Onboarding docs should consume:

- final classification
- mitigation requirement (if any)
- proof artifact path

Reference workflows:

- `ace-monorepo-e2e/test/e2e/TS-MONO-001-rubygems-install/` (primary — E2E scenario with proof logic)
- `wfi://release/rubygems-publish` (recommends running the verification after publish)
- `wfi://release/publish` (references proof classification in final checklist)
