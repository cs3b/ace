---
id: 8wr.t.uj0
status: in-progress
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
- [ ] SC4: Record the real supported Lab fj version/help and a read-only selected-repository smoke test, with credentials redacted. Endpoint unavailability leaves this criterion open, never replaced by mocks. — OPEN: no Lab `fj` binary/credentials reachable from the workstation; upstream v0.6.0 binary observed (help + real-server read-only probes) and qk1.0 Lab fixtures corroborate shapes; evidence in `evidence/fj-capabilities.md`.
- [ ] SC5: Execute bin/ace-test ace-git-forgejo all, bin/ace-test ace-git-worktree all and bin/ace-test-suite; independent review binds the accepted candidate SHA. CI is advisory.

## Slice and scope
One medium provider correctness slice. No consumer migration, publication, new Forgejo HTTP fallback, or destructive live endpoint test. qk1.0 is already delivered. See ux/usage.md for calls; existing follow-up origin: qk1.0 review findings 8wruavkr and 8wruavkw.

## Review decisions
2026-09-29, source e45679c1e: provider.rb fj/send_mutation omit server context. The original pending spec lacked explicit unsupported/mismatch semantics and context; returned to draft for review. The real fj surface is implementation verification evidence, not permission to choose a weaker behavioral contract. No human policy question remains.
