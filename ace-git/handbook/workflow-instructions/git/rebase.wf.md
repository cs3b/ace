---
name: git/rebase
allowed-tools: Bash, Read
description: Rebase feature branch with state capture, continue-first conflict handling, escalation to cherry-pick, and post-rebase verification
argument-hint: "[target-branch] [--no-verify]"
doc-type: workflow
purpose: Safe rebase workflow with state capture, explicit conflict triage, and verification
update:
  frequency: on-change
  last-updated: '2026-03-09'
---

# Rebase Workflow

## Purpose

Rebase feature branches against a target branch with automatic state capture for recovery and verification. The workflow attempts simple rebase first, keeps localized conflicts on the normal rebase path, and escalates to cherry-pick only when per-commit replay is the safer tool.

## Requirements

- **Bash 4+**: Required for array syntax (macOS: install via Homebrew)
- **ace-b36ts**: For generating compact session IDs

## Strategies

| Strategy | Trigger | Description |
|----------|---------|-------------|
| **simple** (DEFAULT) | No conflicts | Standard `git rebase` - preserves exact commit history |
| **continue-first** | Small or localized conflict set | Resolve the conflict and continue the existing rebase |
| **cherry-pick** (ESCALATION) | Repeated conflicts, large conflict set, or explicit request | Per-commit replay from cached commit list |

> For interactive history editing, see [Appendix: Alternative Strategies](#appendix-alternative-strategies).

## Variables & Helpers

```bash
# Variables
# $target_branch: Branch to rebase against (default: auto-detect or origin/main)
# $no_verify: Skip post-rebase verification (default: false)

# Helper: Auto-detect target branch from task spec or default to origin/main
get_target_branch() {
  local task_file
  task_file=$(ls _current/*.s.md 2>/dev/null | head -1)
  if [ -n "$task_file" ] && [ -f "$task_file" ] && [ -r "$task_file" ]; then
    ruby -ryaml -e '
      c = File.read(ARGV[0])
      if c.start_with?("---")
        yaml_content = c.split("---", 3)[1]
        if yaml_content
          data = YAML.safe_load(yaml_content, permitted_classes: [Symbol])
          puts data.dig("worktree", "target_branch") || "origin/main"
        else
          puts "origin/main"
        end
      else
        puts "origin/main"
      end
    ' "$task_file" 2>/dev/null || echo "origin/main"
  else
    echo "origin/main"
  fi
}

# Helper: Recover session variables (for multi-shell workflows)
recover_session() {
  if [ -n "$cache_dir" ]; then return; fi
  sessions=($(ls -td .ace-local/git/*-rebase 2>/dev/null))
  if [ ${#sessions[@]} -eq 0 ]; then
    echo "ERROR: No rebase sessions found"; exit 1
  elif [ ${#sessions[@]} -eq 1 ]; then
    cache_dir="${sessions[0]}"
  else
    echo "Multiple sessions found:"
    for i in "${!sessions[@]}"; do
      echo "  [$i] $(basename ${sessions[$i]} | sed 's/-rebase$//')"
    done
    read -p "Select (Enter for most recent): " choice
    if [ -z "$choice" ]; then
      cache_dir="${sessions[0]}"
    elif echo "$choice" | grep -qE '^[0-9]+$' && [ "$choice" -lt ${#sessions[@]} ]; then
      cache_dir="${sessions[$choice]}"
    else
      echo "ERROR: Invalid selection"; exit 1
    fi
  fi
  session_id=$(basename "$cache_dir" | sed 's/-rebase$//')
  target_branch=$(grep "target_branch:" "$cache_dir/metadata.yml" | cut -d' ' -f2)
  export cache_dir session_id target_branch
  echo "Recovered session: $session_id"
}
```

**Session Continuity:** If continuing in a new shell, call `recover_session` before any phase. Variables `cache_dir`, `session_id`, and `target_branch` are exported for subprocess visibility.

**Conflict Policy:** The first conflict stays on the normal rebase path unless the conflict set is clearly large or the operator explicitly wants per-commit replay. Cherry-pick fallback is the escalation path, not the default response to every conflict.

---

## Phase 1: State Capture

### 1.1 Initialize Session

```bash
# Set target branch
target_branch="${target_branch:-$(get_target_branch)}"

# Generate session ID and cache directory
session_id=$(ace-b36ts encode now)
cache_dir=".ace-local/git/${session_id}-rebase"
mkdir -p "$cache_dir"
export cache_dir session_id target_branch

echo "Session: $session_id | Target: $target_branch | Cache: $cache_dir"
```

### 1.2 Capture Pre-Rebase State

```bash
git fetch origin
merge_base=$(git merge-base HEAD "$target_branch")

# Metadata
cat > "$cache_dir/metadata.yml" << EOF
session_id: $session_id
target_branch: $target_branch
source_branch: $(git branch --show-current)
source_head: $(git rev-parse HEAD)
merge_base: $merge_base
started_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

# Commit list (oldest first for cherry-pick replay)
git log --reverse --oneline "$merge_base"..HEAD > "$cache_dir/commits.txt"
: > "$cache_dir/applied-shas.txt"

# Diffs for recovery and verification
git diff "$merge_base"..HEAD > "$cache_dir/pre-rebase.diff"
git diff --stat "$merge_base"..HEAD > "$cache_dir/pre-rebase.stats"
```

### 1.3 Validate State

```bash
# Check working directory is clean
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "ERROR: Working directory not clean. Commit or stash changes first."
  exit 1
fi

# Warn about untracked files
untracked=$(git status --porcelain=v1 | grep '^[??]' | wc -l | tr -d ' ')
if [ "$untracked" -gt 0 ]; then
  echo "WARNING: $untracked untracked file(s) may be deleted during rebase cleanup."
  git status --porcelain=v1 | grep '^[??]'
  read -p "Press Enter to continue (or Ctrl+C to abort): "
fi

# Check commits exist
commit_count=$(wc -l < "$cache_dir/commits.txt" | tr -d ' ')
if [ "$commit_count" -eq 0 ]; then
  echo "Already up to date with $target_branch"; exit 0
fi

echo "Commits to rebase: $commit_count"
cat "$cache_dir/commits.txt"
```

---

## Phase 2: Simple Rebase

### 2.1 Attempt Rebase

```bash
echo "Attempting simple rebase onto $target_branch..."
git rebase "$target_branch"
```

### 2.2 Triage First Conflict

```bash
# If conflicts detected, inspect them before changing strategies
if [ -d ".git/rebase-merge" ] || [ -d ".git/rebase-apply" ]; then
  conflicted_files=($(git diff --name-only --diff-filter=U))
  conflict_count=${#conflicted_files[@]}
  current_commit=$(git rev-parse --short REBASE_HEAD 2>/dev/null || echo "unknown")

  echo "Conflict detected in rebase commit: $current_commit"
  printf '  %s\n' "${conflicted_files[@]}"

  if [ "$conflict_count" -le 2 ]; then
    echo "Strategy: continue-first"
    echo "Resolve conflicts, then run: git add <files> && git rebase --continue"
    echo "Escalate only if the next rebase stop is also conflicted or resolution coordination becomes complex."
    echo "CHANGELOG.md note: prefer git checkout --theirs CHANGELOG.md, then re-apply your entries on top before git add."
  else
    echo "Strategy: cherry-pick fallback (conflict set is large)"
    echo "Abort the rebase and proceed to Phase 3."
  fi
else
  echo "Simple rebase complete - proceed to Phase 4"
fi
```

### 2.3 Escalate to Cherry-Pick Only When Needed

```bash
# Use this only after triage says the conflict set is large, repeated, or explicitly requires per-commit replay
git rebase --abort || rm -rf .git/rebase-merge .git/rebase-apply
git reset --hard HEAD
echo "WARNING: About to delete untracked files."
read -p "Press Enter to continue with git clean -fd (or Ctrl+C): "
git clean -fd
# Proceed to Phase 3
```

---

## Phase 3: Cherry-Pick Fallback

Use this path only after the first-conflict triage says normal rebase is no longer the right tool.

### 3.1 Setup Work Branch

```bash
recover_session  # Ensure session variables are set

original_branch=$(git branch --show-current)
git branch -m "$original_branch" "${original_branch}-backup-${session_id}"
git checkout --no-track -B "${original_branch}-rebase-${session_id}" "$target_branch"
```

### 3.2 Apply Commits

```bash
while IFS=' ' read -r sha msg; do
  # Skip commits already recorded in this replay session
  if grep -qxF "$sha" "$cache_dir/applied-shas.txt"; then
    echo "Skipping (already applied): $sha"
    continue
  fi

  echo "Applying: $sha $msg"
  if ! git cherry-pick "$sha"; then
    echo ""
    echo "CONFLICT in: $sha - $msg"
    echo ""
    echo "To resolve:"
    echo "  1. Fix conflicts, then: git add <files> && git cherry-pick --continue"
    echo "  2. Record the replayed SHA after continue: echo $sha >> $cache_dir/applied-shas.txt"
    echo "  3. Re-run Phase 3.2 (already-applied SHAs will be skipped)"
    echo ""
    echo "To skip: git cherry-pick --skip"
    echo "To abort: git cherry-pick --abort && git checkout ${original_branch}-backup-${session_id}"
    exit 1
  fi

  echo "$sha" >> "$cache_dir/applied-shas.txt"
done < "$cache_dir/commits.txt"
```

### 3.3 Finalize

```bash
git branch -m "${original_branch}-rebase-${session_id}" "$original_branch"
# Restore tracking — git branch -m drops upstream config
git branch --set-upstream-to="origin/${original_branch}" "$original_branch"
echo "Cherry-pick complete. Backup at: ${original_branch}-backup-${session_id}"
```

---

## Phase 4: Verification

### 4.1 Generate Post-Rebase Stats

```bash
recover_session  # Ensure session variables are set

if [ "$no_verify" = "true" ]; then
  echo "Verification skipped (--no-verify)"
else
  new_merge_base=$(git merge-base HEAD "$target_branch")
  git diff --stat "$new_merge_base"..HEAD > "$cache_dir/post-rebase.stats"
```

### 4.2 Compare & Report

```bash
  echo "=== Verification Report ==="
  echo "Pre:  $(tail -1 "$cache_dir/pre-rebase.stats")"
  echo "Post: $(tail -1 "$cache_dir/post-rebase.stats")"

  # Compare commit counts (primary check)
  pre_commits=$(wc -l < "$cache_dir/commits.txt" | tr -d ' ')
  post_commits=$(git log --oneline "$new_merge_base"..HEAD | wc -l | tr -d ' ')

  if [ "$pre_commits" = "$post_commits" ]; then
    echo "Commits: MATCH ($pre_commits)"
  else
    echo "Commits: MISMATCH (pre: $pre_commits, post: $post_commits)"
  fi

  # Compare file counts (secondary check)
  pre_files=$(grep -cE "^diff --git" "$cache_dir/pre-rebase.diff" 2>/dev/null || echo 0)
  post_files=$(git diff --name-only "$new_merge_base"..HEAD | wc -l | tr -d ' ')
  echo "Files: pre=$pre_files, post=$post_files"
fi
```

---

## Phase 5: Push Changes

```bash
# Run tests before pushing
if ! ace-test; then
  echo "ERROR: Tests failed. Fix before pushing."
  exit 1
fi

# Force push and set upstream tracking (-u ensures branch tracks remote after rename)
git push --force-with-lease -u origin "$(git branch --show-current)"
```

---

## Recovery

### Using Cached Data

```bash
# Find session
ls -td .ace-local/git/*-rebase/ | head -5

# Set variables
cache_dir=$(ls -td .ace-local/git/*-rebase 2>/dev/null | head -1)
cat "$cache_dir/metadata.yml"

# Reset to original HEAD
original_head=$(grep "source_head:" "$cache_dir/metadata.yml" | cut -d' ' -f2)
git reset --hard "$original_head"
```

### Cache Cleanup

```bash
# Remove specific session
rm -rf "$cache_dir"

# Clean sessions older than 7 days
find .ace-local/git -name "*-rebase" -type d -mtime +7 -exec rm -rf {} +
```

---

## Edge Cases

| Case | Detection | Handling |
|------|-----------|----------|
| Already up to date | `commit_count -eq 0` | Exit cleanly in Phase 1.3 |
| Single commit | `commit_count -eq 1` | Simple rebase (no cherry-pick benefit) |
| Rebase in progress | `.git/rebase-merge` exists | Prompt: `--continue` or `--abort` |

---

## Appendix: Alternative Strategies

### Manual Conflict Resolution

```bash
git rebase "$target_branch"
# On conflict: resolve files, git add, git rebase --continue
# Escalate to Phase 3 only if conflicts keep repeating or require per-commit replay
# CHANGELOG: git checkout --theirs CHANGELOG.md, add your entries on top
```

### Interactive Rebase

```bash
git rebase -i "$target_branch"
# pick/squash/reword/edit/drop commits in editor
# git rebase --continue after each stop
```

---

## Success Criteria

- State captured to `.ace-local/git/{id}-rebase/`
- Branch rebased on target (simple, continue-first, or cherry-pick)
- Stats verified (or --no-verify)
- Tests pass
- Pushed with --force-with-lease

## Response Template

```
Session: {id} | Strategy: simple|continue-first|cherry-pick
Target: {branch} | Commits: {count}
Verification: {MATCH|MISMATCH} | Tests: {Pass|Fail}
Reason: {no-conflicts|localized-conflict|repeated-conflicts|large-conflict-set|user-request}
Status: {Complete|Needs attention}
```
