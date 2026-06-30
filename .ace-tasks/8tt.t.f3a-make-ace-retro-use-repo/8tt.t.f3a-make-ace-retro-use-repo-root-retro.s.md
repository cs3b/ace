---
id: 8tt.t.f3a
status: done
priority: medium
created_at: "2026-06-30 10:03:39"
estimate: TBD
dependencies: []
tags: []
github_issue: 305
---

# Make ace-retro use repo-root retro workspace consistently

## Behavioral Specification

### User Experience

- **Input:** A user runs `ace-retro create`, `ace-retro list`, `ace-retro show`, `ace-retro update`, or `ace-retro doctor` from either the repository root or a nested project subdirectory.
- **Process:** `ace-retro` resolves its default retrospective workspace once, using the repository/project root as the base for `.ace-retros`.
- **Output:** Retros created from a nested subdirectory are stored under the canonical root `.ace-retros/` directory and remain visible to root-level listing, showing, updating, and doctor checks.

### Expected Behavior

`ace-retro` should default all retrospective operations to the same repo-root workspace. If a user runs `ace-retro create "my-retro" --type standard` from `repo/app/`, the created retro path should be under `repo/.ace-retros/`, not `repo/app/.ace-retros/`. Running `ace-retro list` from `repo/` should show that retro without requiring manual file movement or a custom `--root` flag.

The explicit `--root` override remains the supported way to operate on a non-default retrospective workspace. Recursive discovery of arbitrary nested `.ace-retros` directories is not part of this task.

### Interface Contract

```bash
cd repo/app
ace-retro create "my-retro" --type standard
# Expected: printed Path points under repo/.ace-retros/

cd repo
ace-retro list
# Expected: output includes "my-retro"

ace-retro list --root /tmp/custom-retros
# Expected: output is scoped to /tmp/custom-retros, preserving the explicit override
```

Error Handling:

- If no repository/project root can be found, existing fallback behavior may continue to use the current working directory as the workspace base.
- If `--root` points to an empty or missing workspace, existing command-specific behavior should remain unchanged.

Edge Cases:

- Running from multiple nested levels inside a repository should still resolve to the same root `.ace-retros/`.
- Existing root-level retros should continue to list, show, update, and pass doctor checks as before.
- Nested `.ace-retros/` directories should not be discovered implicitly unless the user passes `--root`.

## Success Criteria

- Creating a retro from a repository subdirectory writes it under the repository root `.ace-retros/`.
- Listing from the repository root shows retros created from nested subdirectories.
- `show`, `update`, and `doctor` operate on the same default root workspace used by `create` and `list`.
- `--root` continues to override the default workspace for list behavior.
- Regression coverage documents and protects the nested-cwd behavior reported in GitHub issue #305.

## Validation Questions

- None open. The chosen policy is that repo-root `.ace-retros/` is canonical by default, and package-local retros require explicit `--root`.

## Vertical Slice Decomposition Task/Subtask Model

- **Slice type:** Standalone task.
- **Slice outcome:** `ace-retro` users get one consistent default retro workspace regardless of current subdirectory.
- **Advisory size:** Small.
- **Context dependencies:** `ace-retro` CLI commands, `RetroConfigLoader`, `RetroManager`, `ProjectRootFinder`, existing `ace-retro` command tests, and GitHub issue #305.

## Verification Plan

### Unit/Component Validation

- Add coverage for default root resolution from a nested cwd inside a temporary git/project tree.
- Add command-level regression coverage showing a retro created from `repo/app/` is stored under `repo/.ace-retros/`.
- Confirm `ace-retro list --root <custom-root>` still scopes list output to the explicit root.

### Integration/E2E Validation If Cross-Boundary Behavior Exists

- If the implementation touches CLI command wiring beyond the config/root resolver, add or update an `ace-retro` E2E scenario so `create` from a nested cwd and `list` from root are exercised together.

### Failure/Invalid Path Validation

- Verify a nested `.ace-retros/` directory is not implicitly scanned by root-level `ace-retro list` unless passed via `--root`.

### Verification Commands

- `ace-test ace-retro` should pass.

## Objective

Fix the issue where retros created from a subdirectory can appear to succeed but become invisible to normal root-level `ace-retro list` usage. Users should not need to know the implementation root rules or manually move files after running a successful create command.

## Scope of Work

- Specify and verify default root consistency for `ace-retro create`, `list`, `show`, `update`, and `doctor`.
- Preserve the existing `--root` override for users who intentionally operate on a non-default workspace.
- Keep behavior focused on a single canonical repo-root retro workspace.

## Deliverables

- Behavioral regression coverage for GitHub issue #305.
- Any minimal implementation adjustment needed to make default root handling consistent.
- Changelog entry for `ace-retro` if code or user-visible behavior changes.

## Out of Scope

- Recursive discovery of nested `.ace-retros/` directories.
- New package-local retro workspace modes.
- New config keys or CLI flags for root policy.
- Broad redesign of `ace-retro` storage.

## References

- GitHub issue: https://github.com/cs3b/ace/issues/305
- Related package: `ace-retro`
- Relevant command override: `ace-retro list --root <path>`
