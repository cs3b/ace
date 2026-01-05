---
id: v.0.9.0+task.150.15
status: done
priority: medium
estimate: S
parent: v.0.9.0+task.150
dependencies:
  - v.0.9.0+task.150.14
---

# 150.15: Add Missing Help Documentation

## Objective

Add `self.help` overrides to the 4 CLIs that are missing custom help sections, following the established pattern.

## Deliverables

### 4 CLIs Need `self.help` Override

#### 1. ace-search

**File**: `ace-search/lib/ace/search/cli.rb`

Document search type auto-detection (file vs content search based on pattern).

#### 2. ace-test-runner

**File**: `ace-test-runner/lib/ace/test_runner/cli.rb`

Document test layer targets (atoms, molecules, organisms, unit).

#### 3. ace-git-worktree

**File**: `ace-git-worktree/lib/ace/git/worktree/cli.rb`

Document task-aware worktree creation (--task, --pr flags).

#### 4. ace-docs

**File**: `ace-docs/exe/ace-docs`

Document document management workflow (status, validate, update).

Also add class_options to ace-docs CLI for consistency.

## Verification

Test each CLI's `--help` output:
```bash
ace-search --help
ace-test --help
ace-git-worktree --help
ace-docs --help
```
