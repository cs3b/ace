---
id: 8wr.t.uj0
status: done
priority: medium
created_at: "2026-09-28 20:21:07"
estimate: medium
dependencies: [8wr.t.qk1.0]
tags: [forge-neutral]
needs_review: false
title: Bind Forgejo provider commands to the selected server repository
bundle:
  presets: [project]
  files: [ace-git-forgejo/lib/ace/git/forgejo/provider.rb, ace-git-forgejo/lib/ace/git/forgejo/cli_executor.rb, ace-git-forgejo/lib/ace/git/forgejo/parsers.rb, ace-git-worktree/lib/ace/git/worktree.rb]
  commands: []
---

# Bind Forgejo provider commands to the selected server repository

## Outcome and ownership
A caller selecting a named Forgejo server operates only on its resolved host/owner/repository, regardless of cwd, default fj login, remote ordering or another checkout. ace-git-forgejo owns identity binding; ace-git-worktree consumes its proof. qk1.1 and qk1.2 reuse this boundary for later operations rather than introducing independent targeting.

## Behavior and public contract
- Input: the existing resolved server and normalized provider operations. Output: existing normalized evidence/receipts with the selected identity, or an existing classified provider failure. No new ACE selection syntax.
- Bind all repository-scoped reads and mutations, including lookup/reconciliation, PR search/view/diff/head, issues, checks, repository lookup, create and update. Authentication is host-scoped and must agree with selection. No temporary chdir, global login switch or modification of user fj configuration to retarget a call.
- The selected identity is mandatory at the common executor boundary. If the installed CLI cannot express that operation for that identity, raise ProviderUnsupportedCapabilityError before sending it; never use ambient repository context. Malformed selection raises configuration failure before subprocess launch. CLI missing/authentication/unreachable/malformed output retain the shared taxonomy.
- Validate the repository identity in returned evidence when available; a conflict is an error, not relabelled evidence. PR numbers alone are not globally unique. Reconciliation after an uncertain mutation uses the same exact identity and must not create again automatically.
- Observe real installed Lab fj version and per-subcommand help before choosing flags. Preserve a sanitized capability/argv fixture in this task's evidence. Unsupported capabilities stay explicit; fixture guesses cannot establish actual support.
- Populate merge-commit evidence only when the observed CLI exposes an authoritative merge commit for the exact selected PR. A head commit, branch tip, exit zero, or merged label alone cannot substitute. Without the field, retain conservatively. A supplied field inconsistent with repository/PR identity fails closed.
- Existing ready/atomic expected-head merge refusals remain. This task does not add those capabilities or claim complete Forgejo delivery; qkb.0 must reconcile them before its delivery acceptance.

## Success criteria and verification
- [x] SC1: A complete current provider operation matrix asserts exact repository/host binding for every subprocess, including reconciliation and error paths. Two repositories with the same PR/issue number and conflicting cwd/login cannot cross-route.
- [x] SC2: Missing capability, invalid identity, wrong returned identity, unavailable CLI and failed auth cause classified failure with no wrongly targeted mutation. No global configuration or cwd changes occur.
- [x] SC3: An authoritative merge SHA reaches worktree cleanup proof; absent/conflicting/malformed evidence retains the checkout. Different repos with identical branch/PR numbers remain distinct. (fj v0.6.0 exposes no authoritative merge field — provider keeps `merge_commit_sha` empty; resolver provenance gate proven both ways.)
- [x] SC4: Record the real supported Lab fj version/help and a read-only selected-repository smoke test, with credentials redacted. Endpoint unavailability leaves this criterion open, never replaced by mocks. — PARTIAL/OPEN on the Lab-specific half: no Lab `fj` binary or credentials reachable from the workstation (Lab API is sign-in-only). Recorded instead: upstream forgejo-cli v0.6.0 release binary executed (per-subcommand help + read-only selected-repository probes against a real Forgejo server, exact bound argv forms), plus qk1.0 real-Lab output fixtures corroborating shapes; evidence in `evidence/fj-capabilities.md`.
- [x] SC5: Execute bin/ace-test ace-git-forgejo all, bin/ace-test ace-git-worktree all and bin/ace-test-suite; independent review binds the accepted candidate SHA. CI is advisory. — forgejo all: 84 tests green; worktree all: 544 green; ace-test-suite: 50 packages, 10274 tests green (twice, incl. after review fixes). Independent review (ace-review code-valid, role:review-codex; gemini broken at CLI level in this environment): round 1 → 2 Medium findings, both fixed with regression tests (63a99bd56, bf47e8a87); round 2 on the full diff → no correctness findings. Session dirs review-8wsndb, review-8wsnl7; verdicts bind the accepted diff e45679c1e..HEAD. PR-level delta round converges at delivery per review budget policy.

## Slice and scope
One medium provider correctness slice. No consumer migration, publication, new Forgejo HTTP fallback, or destructive live endpoint test. qk1.0 is already delivered. See ux/usage.md for calls; existing follow-up origin: qk1.0 review findings 8wruavkr and 8wruavkw.

## Review decisions
2026-09-29, source e45679c1e: provider.rb fj/send_mutation omit server context. The original pending spec lacked explicit unsupported/mismatch semantics and context; returned to draft for review. The real fj surface is implementation verification evidence, not permission to choose a weaker behavioral contract. No human policy question remains.

2026-09-29 implementation review (code-valid, role:review-codex): round 1 findings — (1) cleanup resolver base_ref compare breaks remote-prefixed targets like origin/main → fixed with remote-name-aware target branch resolution + tests; (2) RepositoryBinding::Target constructor public → forged targets could bypass validation → constructor privatized behind Target.resolve + test. Round 2 on full diff: no correctness findings. Open QA note (Lab smoke test) = SC4's documented open half, environmental.

2026-09-29 astra review of origin/main..main (codex:astra:high, session review-8wsp6w, operator-directed): (1) HIGH — fj keys-file aliases silently override `-H` (verified against the real binary: alias codeberg.org→127.0.0.1:9 redirected the request) → fixed with a read-only alias-conflict guard at the observed v0.6.0 keys-file locations; conflicting alias raises ConfigError before any repository subprocess, absent/unreadable file allows. (2) MEDIUM — `-H` dropped the selected scheme (fj assumes HTTPS for a bare host; verified `http://` full-URL -H preserves scheme+port) → executor now passes scheme://authority; non-http(s) schemes rejected pre-subprocess. (3) MEDIUM — fully qualified cleanup targets (refs/heads/main, refs/remotes/origin/main) wrongly conflicted → normalized in target_branch with remote-name awareness + regression tests. All three findings reproduced/verified against the observed binary before fixing; forgejo 87 / worktree 545 / support-cli 62 / suite 50 pkgs 10278 green after fixes.

## Closure reconciliation — 2026-10-02
Captain explicitly accepted this task as closed. Repository-binding implementation and recorded tests/reviews are delivered on main (f823c6572, f30f5bf7f, 54ea07be4). Status corrected to done. The SC4 text above preserves its historical limitation: no new test of the currently installed Lab fj was performed here. That endpoint-specific proof is carried by existing acceptance owner ACE 8wr.t.qkc, required before its matrix closes; do not present upstream binary probes as the Lab smoke result.
