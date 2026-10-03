---
id: 8wr.t.qk1
status: done
priority: high
created_at: "2026-09-28 17:42:16"
estimate: TBD
dependencies: [8wk.t.l1e]
tags: [lab-readiness]
bundle:
  presets: [project]
  files: [.ace-tasks/_archive/8w/y/8wk.t.l1e-forge-neutral-git-core-with/8wk.t.l1e-forge-neutral-git-core-with-github-and.s.md, ace-git/lib/ace/git/providers/base.rb, ace-git/lib/ace/git/providers/evidence.rb, ace-git/lib/ace/git/server_registry.rb, .ace-tasks/_archive/8x/v/8wr.t.qk1-complete-forge-neutral-worktree-review/ux/usage.md]
  commands: []
needs_review: false
position: 6o000h
---

# Complete forge-neutral worktree review and task consumers

## Outcome and current evidence

Users create worktrees, review PRs and synchronize task issues on GitHub, default Forgejo and another named Forgejo through the same public ACE behavior. Local Git/task/review inputs remain usable without forge configuration, credentials or binaries.

Foundation ace:8wk.t.l1e is delivered; its scope explicitly excluded these consumers. At drafting, `Providers::Base` supported read-only evidence and consumers used GitHub-specific helpers. All three children have now replaced those operational consumer paths; the historical limitation is not a statement of current code. The old lab-overseer l2d.3–.5 mandates now consume this owner's receipts, rather than own duplicate implementation.

## Decomposition and ownership

| Child | Observable delivered result | Additional shared surface owned here |
|---|---|---|
| qk1.0 | Create/inspect/preview cleanup for PR worktrees on either forge | Neutral PR lifecycle CLI and provider mutations, head provenance needed by worktree/task creation |
| qk1.1 | Review exact PR heads and collect/post comments on either forge | Provider-neutral review/comment evidence and comment mutations |
| qk1.2 | Link and sync local tasks to exact issues on either forge | Neutral issue-link metadata and sync/provider behavior |

qk1.0 comes first and establishes usable neutral PR behavior; qk1.1 and .2 then execute independently. Shared read contract remains ace-git plus provider adapters, not a fourth contract package. Each slice includes its necessary provider extensions and tests; no empty foundation-only subtask. All child specs must pass independent review before parent promotion.

## Shared interface and selection

- Relevant remote commands accept `--server NAME` or `--default-server`, mutually exclusive. Neither option means resolve the configured repository remote through existing ServerRegistry.resolve_remote; no fallback to default on failed remote resolution.
- `--default-server` calls resolve_default; exactly one default is required for that call. A configuration with no default is valid for explicitly selected/local operations. `--server` calls resolve(NAME).
- A PR/issue URL is accepted only when its repository matches exactly one configured server. Explicit selection must match that URL; mismatch fails before mutation. A bare number uses the selected/remote-resolved repository. Existing `owner/repo#number` works only when one configured entry matches that repository; it never infers github.com.
- Resolve once per operation and retain `{server_name, provider, repository_url, object_kind, number, url}` with exact head SHA for PR evidence. Persisted links/attempt evidence retain this identity even if the default changes; changed configuration identity for the same server name is a conflict, not retargeting.
- Use existing core evidence types and extend them for head repository/ref and mutation receipts as needed by children. Consumers treat missing required head/provenance as a classified error. Provider optional data must never erase identity.
- `--format json` on the new neutral PR commands emits structured evidence; text names server/provider/object/head. Success is exit 0 only with operation evidence; invalid input/provider failure is nonzero and retains existing classified provider failures. Unknown operation outcome is a distinct non-success with reconciliation context, never an automatic retry.
- Provider mutation APIs receive expected head for PR-changing operations where stale state matters. Require the provider to enforce the condition; unsupported atomic merge preconditions return an unsupported-capability failure, not a check-then-merge race.

## Success criteria and verification

Each child proves local-only isolation and all three remote variants, plus invalid identity/auth/offline/malformed outcomes. No consumer assumes GitHub parser/output shape; each old direct call is removed or recorded as non-operational metadata in the coupling inventory. Shared errors never trigger another provider or curl fallback. Child tests use controlled IO, real temporary Git and provider contract fixtures; full authorized endpoint matrix belongs qkc.

Run `ace-test` all for each changed package and `ace-test-suite`; report exact commands/results and independent review. Aggregate child receipts for lab-overseer l2d.3–.5. The umbrella does not implement hidden behavior or run a duplicate matrix.

## Boundaries and decisions

Umbrella; advisory size: large. Provider mutation extensions are necessary because the delivered base is read-only. Canonical assignment/role workflow migration belongs qkb; runtime switching belongs k86; durable attempts belong qjl. No backward compatibility, automatic migration or aliases for removed GitHub-specific public commands. Existing repository metadata referencing removed keys is updated within implementation where authored; unsupported old user input fails with the new syntax, never silently converted. No blocking product questions.

## Child delivery reconciliation — 2026-10-04

- [x] qk1.0: PR347, child report.md retains provider/core/worktree tests, independent astra review and explicitly delegated uj0 correction. Required full delivery capabilities were outside this historical safe-refusal acceptance; new z78 owns them.
- [x] qk1.1: PR360 merged f345d7feb024aa3366e54bdf7cf863964b4ccd58; child review-delivery-2026-10-02.md preserves exact-head 37190e744 independent approval/check receipts and package counts. It also preserves the then-blocked campaign finish, which must not be represented as a successful finish. Main later contains campaign repair 3d40a79c3; final R2/R3 acceptance remains separate.
- [x] qk1.2: PR359 merged 2cae1345bad3d08d3a27144c7fa626c123377bdb; child verification-2026-10-02.md plus review-delivery-2026-10-02.md preserve tests, executed independent review coverage, campaign bookkeeping limitations and Medium follow-ups. Do not rewrite a rejected campaign finish as accepted or claim a new exact-head campaign receipt.

Current source recheck at 46b980777 confirms the named-provider consumer boundaries. The preceding program review executed review all 941, task all 493, Forgejo all 118 and default suite 10,944 passing, no errors; see lq1/evidence/program-reconciliation-2026-10-04.md for non-frozen-revision limitation. This aggregate is a closure of the delivered consumer migration under the existing merged-child decisions, not installed endpoint proof or R2/R3 completion. qkc remains the full matrix gate; z78 addresses missing provider operations. Independent specification reviewer checks this disposition before parent closure.
