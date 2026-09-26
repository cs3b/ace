---
id: 8vb.t.vyq.0
status: done
priority: medium
created_at: "2026-08-12 21:18:42"
estimate: TBD
dependencies: []
tags: [worktree, cleanup, reporting, ancestry]
parent: 8vb.t.vyq
bundle:
  presets: [project]
  files: [ace-git-worktree/lib/ace/git/worktree/cli.rb, ace-git-worktree/lib/ace/git/worktree/configuration.rb, ace-git-worktree/lib/ace/git/worktree/molecules/worktree_lister.rb, ace-git-worktree/lib/ace/git/worktree/molecules/worktree_remover.rb, ace-git-worktree/lib/ace/git/worktree/models/worktree_info.rb, ace-git-worktree/test/fast/molecules/worktree_lister_test.rb, ace-git-worktree/test/feat/worktree_manager_contract_test.rb]
  commands: [ace-git-worktree list --format json, ace-git-worktree prune --dry-run, ace-test ace-git-worktree all]
needs_review: false
---

# Report repository inventory with ancestry proof

## Behavioral Specification

### User Experience

- **Input:** `ace-git-worktree cleanup` receives an explicit target and remote, with optional offline and JSON modes.
- **Process:** ACE resolves the common repository, captures each worktree and ref independently, proves ancestry where possible, and constructs an ordered no-mutation plan.
- **Output:** A deterministic report shows what could be removed, what must remain, why, and the digest for the complete plan.

### Expected Behavior

- Inventory includes every linked worktree, local ref, and selected-remote ref even when one branch exists in only one category.
- Each worktree reports path, primary/linked status, checked-out ref and SHA, staged/unstaged/untracked paths, locks or protection, and relationship to the target.
- Each ref reports full name, SHA, upstream/association when known, protection, ancestry result, proof, proposed action, and retention reason.
- Reporting refreshes remote evidence without updating local or remote-tracking refs; `--offline` uses only existing local objects and labels unavailable evidence.
- Primary checkout, dirty worktrees, protected items, and unresolved evidence are retained.

### Interface Contract

```text
ace-git-worktree cleanup --target <ref> --remote <name> [--offline] [--format json]
```

Structured output has a versioned schema containing repository/common-dir, target and remote SHAs, refresh/offline status, provider status, normalized inventories, proposed ordered actions, blockers, and `plan_digest`.

Error Handling:

- A missing or ambiguous common repository, target, or remote returns nonzero with no mutation.
- Remote refresh failure degrades to locally provable ancestry and explicitly unresolved remote state.
- Git status or ref-read failure retains the affected item and records the command/evidence failure.

Edge Cases:

- Invocation from a nested directory or linked worktree resolves to the same common repository and report.
- Detached heads, symbolic refs, duplicate checkouts, stale worktree metadata, and deleted remotes remain visible and retained unless proven safe.
- Object-only evidence refresh may populate the object database but never changes refs or checkout content.

## Success Criteria

- Worktrees, local refs, and remote refs are inventoried independently with no omitted one-sided entries.
- Dirty state distinguishes staged, unstaged, and untracked paths.
- Report mode leaves worktrees, checkout content, local refs, remote-tracking refs, and remote refs unchanged.
- Root, nested, and linked-worktree invocation produces semantically identical normalized inventory and digest.
- Ancestry-proven items are classified; protected, dirty, unresolved, and unproven items are retained with reasons.
- Repeated reports over unchanged evidence produce the same canonical digest.

## Validation Questions

- None open. Explicit target/remote selection and ref-safe report behavior are fixed by issue #312.

## Vertical Slice Decomposition Task/Subtask Model

- **Slice type:** Orchestrator subtask
- **Slice outcome:** Maintainers can review a complete cleanup plan before any destructive operation exists
- **Advisory size:** Large
- **Context dependencies:** Worktree CLI/configuration, listing/removal models, Git status/ref evidence

## Verification Plan

### Unit/Component Validation

- Verify common-dir resolution, independent inventories, dirty classes, protection, ancestry, ordering, and canonical JSON/digest.

### Integration/E2E Validation If Cross-Boundary Behavior Exists

- Compare root, nested, linked, online, and offline reports across one-sided refs and multiple worktrees.

### Failure/Invalid Path Validation

- Missing target/remote, failed status, detached heads, stale metadata, and failed refresh retain all uncertain state and perform no mutation.

### Verification Commands

- `ace-test ace-git-worktree all`
- `ace-test-suite --target fast`

## Objective

Establish a complete, deterministic, report-only worktree cleanup inventory using ancestry as the first safe proof.

## Scope of Work

- Cleanup report CLI and structured schema
- Common-repository and target/remote resolution
- Independent worktree/local/remote inventories
- Dirty/protection/ancestry classification and canonical digest

## Deliverables

### Behavioral Specifications

- Report schema, no-mutation guarantees, and retention policy

### Validation Artifacts

- Entry-point equivalence, inventory completeness, and failure scenarios

## Out of Scope

- GitHub squash-merge proof (`8vb.t.vyq.1`)
- Applying cleanup plans (`8vb.t.vyq.2`)

## References

- https://github.com/cs3b/ace/issues/312
- Parent `8vb.t.vyq`
- `../ux-usage.md`
