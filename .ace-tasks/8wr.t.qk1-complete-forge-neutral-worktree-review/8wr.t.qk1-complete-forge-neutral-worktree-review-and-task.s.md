---
id: 8wr.t.qk1
status: in-progress
priority: high
created_at: "2026-09-28 17:42:16"
estimate: TBD
dependencies: [8wk.t.l1e]
tags: [lab-readiness]
bundle:
  presets: [project]
  files: [.ace-tasks/_archive/8w/y/8wk.t.l1e-forge-neutral-git-core-with/8wk.t.l1e-forge-neutral-git-core-with-github-and.s.md, ace-git/lib/ace/git/providers/base.rb, ace-git/lib/ace/git/providers/evidence.rb, ace-git/lib/ace/git/server_registry.rb, .ace-tasks/8wr.t.qk1-complete-forge-neutral-worktree-review/ux/usage.md]
  commands: []
needs_review: false
position: 6o000h
---

# Complete forge-neutral worktree review and task consumers

## Outcome and current evidence

Users create worktrees, review PRs and synchronize task issues on GitHub, default Forgejo and another named Forgejo through the same public ACE behavior. Local Git/task/review inputs remain usable without forge configuration, credentials or binaries.

Foundation ace:8wk.t.l1e is delivered; its scope explicitly excluded these consumers. Existing `Providers::Base` supports read-only PR/diff/issues/check/repository evidence. Worktree creation still calls `Github::PrFetcher`, review calls Github CLI/comment modules, and task sync uses GithubIssueSyncAdapter. The old lab-overseer l2d.3–.5 mandates now consume this owner's receipts, rather than own duplicate implementation.

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
