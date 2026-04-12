---
id: 8qriwa
title: selfimprove-rubygems-release-discovery
type: self-improvement
tags: [process-fix]
created_at: "2026-03-28 12:35:52"
status: active
---

# selfimprove-rubygems-release-discovery

## What Went Well

- The mistaken release-scope conclusion was caught quickly by comparing the workflow guidance against real `gem search` output.
- A reusable helper script, `bin/ace-rubygems-needs-release`, now exists to derive the pending release set from a single RubyGems fetch.

## What Could Be Improved

- The RubyGems publish workflow used a broken fallback command, `gem search "^ace-<name>$" --remote --exact --versions`, even though `--exact` expects the plain gem name.
- The workflow encouraged per-gem remote checks instead of preferring the single-fetch helper script when available.
- The workflow lacked a validation note clarifying the correct `gem search --exact` usage, which made the mistake easy to repeat.

## Action Items

- Updated `.ace-handbook/workflow-instructions/release/rubygems-publish.wf.md` to prefer `bin/ace-rubygems-needs-release`, correct the fallback command, and document the `--exact` validation rule.
- Updated `ace-handbook/handbook/skills/as-release-rubygems-publish/SKILL.md` to tell agents to prefer the helper script for pending-release discovery when present.
- Expected impact: release discovery now uses one RubyGems snapshot when possible, avoids false "all gems are new" conclusions, and keeps the per-gem fallback correct when the helper script is unavailable.
