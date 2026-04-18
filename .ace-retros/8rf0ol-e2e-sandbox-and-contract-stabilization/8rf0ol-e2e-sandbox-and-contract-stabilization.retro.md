---
id: 8rf0ol
title: e2e-sandbox-and-contract-stabilization
type: self-review
tags: []
created_at: "2026-04-16 00:27:19"
status: done
---

# e2e-sandbox-and-contract-stabilization

## What I Did Well

- Drove the E2E failure set iteratively instead of treating the first suite report as the only source of truth.
- Reduced a broad, noisy red suite into clearer failure buckets by rerunning targeted scenarios and reading per-scenario reports instead of relying only on package-level suite summaries.
- Fixed meaningful infrastructure issues in the sandbox path:
  - setup now inherits the sandbox runtime environment
  - tmux commands use explicit socket targeting
  - runtime and socket directories are permission-hardened for isolated tmux use
- Correctly shifted several brittle E2E verifiers toward user-visible behavior instead of hard artifact presence, especially in `ace-search`, `ace-sim`, `ace-review`, `ace-task`, and `ace-git-commit`.
- Preserved momentum across multiple layers of failures and avoided reverting unrelated work while patching many packages in one session.

## What I Could Improve

- I mixed infrastructure stabilization, product fixes, and verifier softening in the same loop. That made it harder to tell when a failure was a real package bug versus a test-contract issue.
- I released packages before the full E2E suite was green. The package releases captured real improvements, but they also locked in a still-moving stabilization effort.
- I spent too much time chasing individual scenario failures before explicitly naming the dominant shared root cause: Bundler and write access assumptions inside the sandbox.
- I did not add a single explicit “environment health” gate early enough. Several scenarios still failed late with read-only filesystem or Bundler startup errors instead of short-circuiting up front.
- Some verifier relaxations were reactive and local. The repo still lacks one consistent policy for:
  - mirrored artifact paths
  - provider-unavailable conditional passes
  - bounded timeout acceptance
  - dry-run equivalence proofs

## Key Learnings

- The remaining suite red is not proportional to the number of root causes. One infra fault can fan out across many scenarios and make progress look smaller than it is.
- `bubblewrap` integration improved isolation, but isolation without a fully consistent writable-runtime contract still leaves Bundler-sensitive commands unstable.
- E2E reports that say `0/0` or lack direct scenario artifact pointers slow triage substantially. Aggregate package reports are useful indexes, but per-scenario reports must remain the source of truth.
- A verifier that is too artifact-specific creates false failures; a verifier that is too vague hides regressions. The right balance is behavior-first with a few explicit observable markers.
- There are still real product issues underneath the infra noise. The clearest current example is the repeated `ace-support-models` sync `TypeError`, which survived beyond verifier and sandbox adjustments.

### Review Cycle Analysis

- The most frequent recurring failure class was environment-level:
  - Bundler trying to write `Gemfile.lock`
  - read-only repo paths during lock or runtime directory creation
  - tmux socket/runtime permission mismatches
- The second recurring class was test-spec drift:
  - missing or renamed artifact files
  - verifier expectations tied to exact wording
  - package-suite mirrored paths not matching scenario-local expectations
- The third class was genuine product mismatch:
  - `ace-support-models` sync orchestration shape handling
  - some CLI flows not surfacing stable IDs or final-state evidence clearly enough
- The practical lesson is that future E2E fix loops should classify failures in this order:
  1. sandbox/runtime health
  2. runner/verifier contract correctness
  3. product logic

## Action Items

### Stop Doing

- Treating every new red scenario as an independent bug before checking whether it belongs to an already-known failure bucket.
- Releasing packages mid-stabilization before the suite reaches a clear completion threshold.
- Letting scenario-specific fixes absorb environment problems that should be solved once in the harness.

### Continue Doing

- Rerunning failing scenarios directly and reading the generated per-scenario reports.
- Using behavior-first verifier language where the user-facing outcome matters more than helper artifact naming.
- Hardening tmux and sandbox runtime paths with explicit, deterministic environment setup.

### Start Doing

- Add an explicit E2E environment preflight that checks:
  - writable runtime/support paths
  - Bundler startup without repo lockfile mutation
  - tmux socket usability inside the sandbox
- Create a shared verifier policy for conditional passes:
  - provider unavailable
  - bounded timeout
  - dry-run equivalence
  - mirrored artifact paths in package-suite runs
- Split future stabilization work into three passes with separate stop conditions:
  1. harness and sandbox fixes
  2. verifier/spec cleanup
  3. product bug fixes
- Improve suite summaries so failed package entries always include a minimal root-cause line and direct scenario-report pointer.
