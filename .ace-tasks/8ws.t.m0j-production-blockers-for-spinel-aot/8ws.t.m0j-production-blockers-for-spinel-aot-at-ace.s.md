---
id: 8ws.t.m0j
status: pending
priority: high
created_at: "2026-09-29 14:40:37"
estimate: 
dependencies: []
tags: [spinel, aot, production, blockers]
---

# Production blockers for Spinel AOT at ace

THE blocker task: what stops shipping Spinel-compiled ace CLIs to production today.

**Compiler gaps (upstream, matz/spinel):** no YAML (Psych), no Date, no Time.parse, no Dir.glob — every ace gem's config cascade needs the shim set; optparse is a silent no-op stub (dangerous class); timeout ignored; encodings unsupported; --rbs seeds drop kw-arg signatures.

**Codegen bugs hit (each cost a workaround):** `class << self; include Module` unmodeled at runtime; constant-receiver class-method dispatch boxes args (Time is a builtin struct — cannot go polymorphic, so Time handling must stay in one static context); dead generic callers poison Time-typed chains (C-level slot mismatches); user-defined +/- operators misbox; bare-ivar readers misbox in poly dispatch; Class.new unsupported; return-in-block misboxes; multiple assignment unsupported; poly String#[range] and gsub! misbox; splat forwarding boxing bugs; dyn-new dispatch arity unions misroute.

**Porting cost:** one small gem (b36ts, zero-dep atoms) took a full session of lowering + shimming. Larger gems (search, task) have heavier organism layers; LLM-shelling gems (llm, git-commit, review — Faraday/external CLIs) are out of reach near-term.

**Distribution work needed:** codesign + notarization for mac-arm64; GH Actions matrix (ubuntu-24.04 x64/arm, macos-14 arm64); multiplexed busybox-style `ace` binary design (one artifact per platform); update story (no gem update); conformance harness integration into ace-test-runner so every compiled CLI is oracle-gated per release.

**Verdict:** viable pilot (b36ts proves it), not yet a production channel. Re-evaluate per Spinel release — the blocker list shrinks fast upstream. Full detail: docs/research/spinel-aot-pilot.md.

Research PR: cs3b/ace#350 (branch spinel-aot-pilot).
