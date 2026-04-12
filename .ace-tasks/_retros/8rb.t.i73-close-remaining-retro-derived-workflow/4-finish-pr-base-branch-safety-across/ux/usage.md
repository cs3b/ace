# Git Base-Branch Safety - Draft Usage

## API Surface

- [ ] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [x] Agent API (git/PR workflows)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Rebase a PR targeting a non-main branch
**Goal**: A maintainer rebases work for a PR whose true base is not `main`.

`ace-bundle wfi://git/rebase`

**Expected Output**: The workflow prefers actual PR/task/worktree base context when available and does not assume `origin/main` unless that is truly the resolved target.

### Scenario 2: Reorganize commits for a feature-branch PR
**Goal**: A maintainer reorganizes commits for a PR stacked on another feature branch.

`ace-bundle wfi://git/reorganize-commits`

**Expected Output**: The workflow resolves or confirms the correct base branch before using it to determine scope, reducing cross-PR rewrite mistakes.

## Notes for Implementer

- Full usage documentation should be completed during work-on-task using `wfi://docs/update-usage`.
