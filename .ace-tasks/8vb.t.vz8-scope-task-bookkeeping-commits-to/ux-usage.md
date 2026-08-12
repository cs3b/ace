# Scope task bookkeeping commits to ACE-owned paths: usage scenarios

## Scenario 1: Preserve unrelated dirty work

**Given** a user has unrelated staged, unstaged, and untracked files  
**And** explicitly enabled task bookkeeping commit behavior  
**When** ACE updates a clean target task path  
**Then** the bookkeeping commit contains only the proven task path and the user's prior index and working-tree state remain exactly intact.

## Scenario 2: Reject a pre-edited task artifact

**Given** the target task file already has a user edit  
**When** task-aware worktree creation begins  
**Then** ACE stops before lifecycle mutation or commit, names the conflicting target path, creates no worktree, and performs no push.

## Scenario 3: Detect hook-expanded commit scope

**Given** a commit hook creates or stages an unrelated file  
**When** the bookkeeping commit returns success  
**Then** ACE audits the commit, detects the unexpected path, stops before worktree creation or push, and reports the commit and recoverable repository state.

## Scenario 4: Handle multiple owned task paths

**Given** one valid lifecycle operation must update a parent and selected subtask artifacts  
**When** ACE proves that finite owned set before mutation  
**Then** the commit may contain exactly those paths and no directory-wide or incidental files.

## Scenario 5: Repeat from a linked worktree

**Given** task-aware creation is invoked from a linked worktree with its own dirty index state  
**When** ACE performs bookkeeping  
**Then** ownership, index preservation, commit audit, and publication guards match repository-root behavior.
