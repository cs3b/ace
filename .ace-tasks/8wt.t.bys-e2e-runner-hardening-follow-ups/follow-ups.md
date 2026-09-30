---
id: auto-generated-on-create
status: draft
priority: medium
created_at: "2026-09-30"
estimate: small
tags: [e2e, hardening]
title: "E2E runner hardening follow-ups from PR #353 review"
---

# E2E runner hardening follow-ups from PR #353 review

## Summary
Deferred hardening findings from the PR #353 review loop (34 delta rounds, budget-exceeded but converging). All are retry-hygiene or architectural refinements of the shared E2E pipeline — none block the published-graph verification deliverable.

## Follow-up items
1. **First-run runner environment allowlist**: the initial deterministic-setup environment still inherits the host process env (filtered of RUBYOPT/RUBYLIB/BUNDLE*/TMUX). Allowlisting it for all scenarios is an architectural change to the shared runtime pipeline (scenarios rely on ambient env for tooling auth). Retry state and reuse paths are already allowlisted.
2. **Manifest validation before runtime preparation**: hoist release-manifest validation above SandboxRuntimeBuilder.prepare so an invalid manifest fails before the bundle-install bootstrap.
3. **Completion record outside the report directory**: move .host-pipeline-complete.json to a host-only location if the report directory is ever exposed to runner-writable confinement changes.
4. **Ownership gate scope**: consider limiting the owned-path gate to CLI-provider runs only, and separate explicit report vs sandbox directories.
5. **Explicit out-of-cache report paths**: currently ERROR with guidance; consider auto-nesting them under the cache root instead.

## Source
PR #353 review rounds 28–34 (sessions review-8wt7zn … review-8wtbah).
