---
id: 8vbgrz
title: selfimprove-rubygems-otp-burst-publish
type: standard
tags: [self-improvement, process-fix, release, rubygems]
created_at: "2026-08-12 11:11:05"
status: done
---

# selfimprove-rubygems-otp-burst-publish

## Incident

Publishing 38 pending ACE gems to RubyGems required multiple OTP rounds. OTP codes (~30–45s) expired mid-queue because builds and per-gem metadata verification ran inside the OTP window, and pushes were strictly sequential.

## Root Cause

- Missing OTP TTL / burst contract in `wfi://release/rubygems-publish`
- Ambiguous timing: OTP collected without guaranteeing all `.gem` artifacts already exist
- Per-push metadata verification added ~2–3s latency per gem inside the critical path
- Auth discovery missed `GEM_HOST_API_KEY` from `mise env` until late

## Fix Applied

Updated:

- `.ace-handbook/workflow-instructions/release/rubygems-publish.wf.md` — hard sequence: credentials → build all → show queue → OTP → ≤5 concurrent dependency waves (≤30s target) → deferred metadata verify; resume on OTP expiry
- `ace-handbook/handbook/workflow-instructions/release/rubygems-publish.wf.md` — same OTP-burst contract documented for project overlays (baseline still non-mutating by default)
- `ace-handbook/handbook/skills/as-release-rubygems-publish/SKILL.md` — OTP timing reminder in execution

## Expected Impact

One OTP should cover a full pending gem queue when agents follow build-all-then-burst. Mid-run OTP failures become resume-with-fresh-OTP instead of rebuild-from-scratch.

## What Went Well

- Helper `.ace-bin/ace-rubygems-needs-release` already gave topo order
- Operator provided fresh OTPs quickly to finish remaining gems

## What Could Be Improved

- Future: optional scripted wave pusher under `.ace-bin/` to make ≤5 concurrent pushes mechanical
- Consider MFA session tokens if RubyGems supports longer-lived publish auth

## Action Items

- [x] Update monorepo rubygems-publish overlay with OTP-burst contract
- [x] Update shipped ace-handbook baseline overlay guidance
- [x] Update as-release-rubygems-publish skill timing note
- [x] Archive this self-improve retro after applying feedback
