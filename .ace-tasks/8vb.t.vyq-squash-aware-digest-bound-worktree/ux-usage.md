# Squash-aware digest-bound worktree cleanup: usage scenarios

## Scenario 1: Review a cleanup plan

**Given** a repository has linked worktrees plus local and remote topic refs  
**When** a maintainer runs `ace-git-worktree cleanup --target origin/main --remote origin`  
**Then** ACE reports every item, proof, proposed action or retention reason, ordered plan, and SHA-256 digest without mutating worktrees or refs.

## Scenario 2: Work without GitHub evidence

**Given** GitHub is unavailable, unauthenticated, or `--offline` is selected  
**When** cleanup evaluates a squash-merged branch  
**Then** ACE uses ancestry-only evidence, retains the unproven branch, and identifies provider evidence as unavailable rather than guessing.

## Scenario 3: Reject approval after drift

**Given** a maintainer approved digest `D` from a report  
**And** a candidate ref advances or a worktree becomes dirty  
**When** the maintainer runs cleanup with `--apply --approved-digest D`  
**Then** ACE reconstructs a different plan, performs no deletion, and reports the evidence that invalidated `D`.

## Scenario 4: Apply an unchanged reviewed plan

**Given** the repository still exactly matches the reviewed report  
**When** cleanup applies its approved digest  
**Then** ACE removes clean worktrees first, exact local refs second, leased remote refs last, and returns a strict final inventory.

## Scenario 5: Preserve state after partial failure

**Given** worktree and local-ref removal succeeds but remote deletion fails  
**When** apply stops  
**Then** ACE lists completed, failed, untouched, and retained operations, performs a final rescan, and requires a new report/digest before any retry.

## Scenario 6: Require only the target

**Given** a protected or dirty non-target item must be retained  
**When** cleanup uses `--require-only-target`  
**Then** ACE preserves the item and exits nonzero with its blocker; strict mode never expands deletion authority.
