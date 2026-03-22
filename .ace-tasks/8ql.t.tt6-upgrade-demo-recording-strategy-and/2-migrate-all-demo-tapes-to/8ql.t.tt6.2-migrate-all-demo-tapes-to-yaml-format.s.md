---
id: 8ql.t.tt6.2
status: pending
priority: medium
created_at: "2026-03-22 19:52:32"
estimate: TBD
dependencies: [8ql.t.tt6.1]
tags: [ace-demo, migration, yaml, tapes]
parent: 8ql.t.tt6
bundle:
  presets: [project]
  files: [ace-demo/lib/ace/demo/organisms/demo_recorder.rb, ace-demo/lib/ace/demo/molecules/tape_resolver.rb, ace-demo/lib/ace/demo/molecules/tape_scanner.rb]
  commands: []
needs_review: false
---

# Migrate All Demo Tapes to YAML Format

## Objective

Convert all 23 package demo tapes from raw `.tape` to structured `.tape.yml` format and upgrade content quality. Each migration creates seed data fixtures, structured scenes showcasing the package's most compelling features, and produces a clean GIF with controlled, realistic data. Old `.tape` files are removed after successful migration.

## Behavioral Specification

### User Experience

- **Input**: Existing `.tape` files in each package's `docs/demo/` directory
- **Process**: For each package: convert `.tape` → `.tape.yml` with structured scenes, create `docs/demo/fixtures/` with realistic seed data where needed, re-record the demo, verify GIF output
- **Output**: All 23 packages have `.tape.yml` files producing high-quality GIFs with controlled data. Old `.tape` files removed.

### Expected Behavior

**Packages needing sandbox + fixtures** (commands need controlled data):
- ace-task, ace-git-commit, ace-git-secrets, ace-git-worktree, ace-review, ace-assign, ace-docs, ace-lint, ace-search, ace-idea, ace-retro, ace-overseer, ace-git

These packages need:
- `docs/demo/fixtures/` directory with realistic seed data (sample files, configs, etc.)
- Setup directives: `sandbox`, `copy-fixtures`, `git-init`, seed commands
- Scenes showcasing filtering, multi-step workflows, and interactive features

**Packages needing minimal/no sandbox** (work with real data or standalone):
- ace-bundle, ace-b36ts, ace-demo, ace-llm, ace-sim, ace-handbook, ace-tmux, ace-prompt-prep, ace-test-runner, ace-test-runner-e2e

These packages need:
- Minimal or no sandbox setup (some may just need `sandbox` + `git-init`)
- Scenes focusing on command output and feature demonstration

**For each package:**
1. Read existing `.tape` to understand current demo content
2. Design `.tape.yml` with upgraded scenes showcasing most compelling features
3. Create `docs/demo/fixtures/` with seed data where commands need controlled environment
4. Write `.tape.yml` with settings, setup, scenes, teardown
5. Record and visually verify GIF output
6. Remove old `.tape` file
7. Update project-level `.ace/demo/tapes/` overrides: migrate getting-started overrides (e.g., `ace-task-getting-started.tape`, `ace-review-getting-started.tape`, `ace-bundle-getting-started.tape`) to `.tape.yml`; remove showcase/test tapes that duplicate migrated content (`test-suite.tape`, `test.tape`, `my-demo.tape`); keep or migrate standalone showcase tapes (`assign-prepare-showcase.tape`, `assign-drive-session-showcase.tape`) as appropriate

**Example migration — ace-task:**
- **Current**: Hardcoded IDs (`8q4.t.ums.2`), runs against 300+ real tasks, flat command sequence
- **Upgraded**: Sandbox with 8-10 seed tasks across statuses/priorities, scenes for `list`, `list --status pending` (showing subset), `create`, `show`, `tree` on orchestrator with subtasks — each scene producing visually distinct output

### Interface Contract

```bash
# After migration, all packages record from .tape.yml
ace-demo record ace-task-getting-started.tape.yml    # → GIF with seed data
ace-demo record ace-review-getting-started.tape.yml  # → GIF with seed PR data
ace-demo record ace-bundle-getting-started.tape.yml  # → GIF with real project data

# ace-demo list shows only .tape.yml files (no .tape remaining)
ace-demo list
# → all entries are .tape.yml format
```

**Fixture directory convention:**
```
<package>/docs/demo/
├── <package>-getting-started.tape.yml    # YAML demo source (committed)
├── <package>-getting-started.gif         # Recorded output (committed)
└── fixtures/                             # Seed data for sandbox (committed, where needed)
    ├── .ace-tasks/                       # Sample tasks (for ace-task)
    ├── sample-file.rb                    # Sample code (for ace-review, ace-lint)
    └── ...
```

### Success Criteria

- [ ] All 23 packages have `.tape.yml` files in `docs/demo/`
- [ ] All 23 `.tape.yml` files record successfully producing GIF output
- [ ] GIFs show realistic, curated data (visual review confirms quality improvement)
- [ ] All old `.tape` files removed from `docs/demo/` directories
- [ ] Project-level `.ace/demo/tapes/` overrides migrated or removed
- [ ] `ace-demo list` shows clean state with only `.tape.yml` entries
- [ ] Fixture directories exist for packages that need controlled data
- [ ] No hardcoded IDs from the live environment in any `.tape.yml`

### Validation Questions

- None — each tape migration is independent and can be verified by recording + visual review

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice**: Subtask of orchestrator — content migration (all 23 packages)
- **Outcome**: All demos migrated to YAML format with controlled data
- **Advisory size**: large (23 packages, but each is independent and formulaic)
- **Context**: Needs ace-demo engine (from subtask 1), each package's existing `.tape` file, understanding of package features

## Verification Plan

### Unit/Component Validation

- [ ] Each `.tape.yml` file parses without error (valid YAML structure)
- [ ] Each fixtures directory contains appropriate seed data for its package

### Integration/E2E Validation

- [ ] `ace-demo record <package>-getting-started.tape.yml` succeeds for all 23 packages
- [ ] Visual review: each GIF shows compelling feature demonstration with controlled data
- [ ] `ace-demo list` shows all 23 tapes in `.tape.yml` format

### Failure/Invalid Path Validation

- [ ] No `.tape` files remain in any `docs/demo/` directory (verified by glob search)
- [ ] No hardcoded live environment IDs in any `.tape.yml` (verified by grep)

## Scope of Work

- **Included**: Converting 23 `.tape` files to `.tape.yml`, creating fixtures, re-recording GIFs, removing old files
- **Excluded**: Engine changes (subtask 1), non-CLI demo removal (subtask 3), built-in preset tapes in `.ace-defaults/`

## Out of Scope

- Changes to the YAML engine or compiler (already done in subtask 1)
- Removal of ace-test demo (subtask 3)
- Migration of built-in preset tapes (`hello.tape`, `ace-test.tape` in `.ace-defaults/`)
