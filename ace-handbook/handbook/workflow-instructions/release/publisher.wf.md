---
name: release-publisher
description: Publisher coworker role — deliver a merged change through release inventory, bumps, build, publication (OTP via a secret HITL ask), and hand off to install/verify
allowed-tools: Bash, Read
doc-type: workflow
title: Release Publisher Workflow
purpose: Bind the publisher role's delivery pass: existing release workflows, short-lived access via ace-lab auth, OTP as a secret HITL case whose wake never carries the value, resume that recognizes already-published artifacts, and the cycle record contract.
ace-docs:
  last-updated: '2026-10-30'
  last-checked: '2026-10-30'
---
# Release Publisher Workflow

## Goal

Deliver a MERGED change to the installed runtime and hand the cycle to
install/verify and the record (task 8xs.t.pu0.9). You are the publisher
coworker: you run the project's existing release workflows — never a private
variant.

## Instructions

Run the loaded workflow as the source of truth and execute it end-to-end
instead of only summarizing it.

### 1) Access

Request the publisher profile through `ace-lab auth` (task 8xs.t.pu0.7):

```bash
ace-lab auth request --profile <publisher-profile> --role publisher \
  --task <task> --assignment <assignment> --repo <repo>
```

Verify principal, repo, scope and use-until before each operation. Static env
profiles expose process-scoped values only and are never proof of remote
expiry. If a wait needs a paused access window, do NOT extend it — request a
fresh lease after the answer.

### 2) Release preparation

Use the existing release workflows exactly: inventory the modified packages,
version bumps, changelogs, and the coordinated release commit
(`ace-bundle wfi://release/local` in ACE-style repos). Do not close the task
at merge when runtime delivery is still required.

### 3) OTP through HITL — a SECRET ask

When publication needs an OTP, ask with the explicit secret flag:

```bash
ace-hitl ask "OTP for gem push" --to captain --kind approval --secret \
  --task <task> --question "One-time code for <publisher step>"
```

`--secret` marks the case AT CREATION (no title heuristics): the armed wake
carries the CASE REFERENCE ONLY — the value never passes through the model.
End the turn after asking; there is no deadline on the Captain's answer and
waiting is never a model loop. Read the value from the case file through the
existing wrapper (the publishing tool consumes it via env/stdin, never argv).
A rejected or expired OTP needs a NEW case — never replay an old value.

### 4) Publication and resume

Publish through the project's existing publication queue. If publication was
interrupted, first check the artifact repository: a matching version AND
digest means ALREADY PUBLISHED — continue with the missing steps only; a
version/digest conflict BLOCKS (never overwrite a version, never bump around
a conflict as a workaround). A failed publication leaves an explicit,
resumable state — never pretend a partially deployed cycle is complete.

### 5) Install, verify, record

After publication, the lab side runs `ace-lab install` convergence (manifest,
gem versions, dependency closure, extension projections) and the runtime
acceptance under the target account — separately evidenced from source and
integration. The cycle's evidence record then goes to
`.ace-tasks/_records/` through a normal reviewed record-only PR
(`ace-bundle wfi://release/cycle-record`). The record-only PR does not
trigger another release without a product change and needs no recursive
record of its own merge. The task closes only after the successful runtime
acceptance AND the integrated record.

## Boundaries

- Source work happens on the host; the lab installs published artifacts.
- Secrets (API keys, OTP) live only in the allowed wrapper/env and the secret
  HITL case — never in prompts, reports, argv, or the wake.
- The live cycle state stays in the existing task/assignment; `_records` is
  the final reviewed evidence write-up, not a control queue.
