# Phase A — Setup Sandbox

## Purpose

Create an isolated git repo inside `experiment/sandbox/` with tooling on PATH,
ready for the runner agent to execute goals.

## Steps

### 1. Create sandbox directory structure

```bash
SANDBOX_DIR="$(cd "$(dirname "$0")" && pwd)/sandbox"
mkdir -p "$SANDBOX_DIR"/{results/{1,2,3,4,5,6,7,8},reports}
```

### 2. Initialize git repo

```bash
cd "$SANDBOX_DIR"
git init
```

### 3. Resolve worktree bin path and write mise.toml

The bin path depends on which worktree we're running from. Resolve it at setup time
and hardcode into the generated mise.toml:

```bash
# Resolve the ace-meta worktree root (works from main repo or any worktree)
WORKTREE_ROOT="$(git -C "$(dirname "$SANDBOX_DIR")" rev-parse --show-toplevel)"
BIN_PATH="$WORKTREE_ROOT/bin"
```

Then write `sandbox/mise.toml`:

```toml
# mise configuration for ace-b36ts E2E experiment sandbox

[vars]
_.file = ["~/.ace/.env"]

[env]
PROJECT_ROOT_PATH = "{{ config_root }}"
ACE_TASKFLOW_PATH = "{{ config_root }}/.ace-taskflow"
LANG = "en_US.UTF-8"
LC_ALL = "en_US.UTF-8"
_.path = ["$BIN_PATH"]  # ← resolved absolute path from worktree

## exposed api keys:
ZAI_API_KEY = { value = "{{vars.ZAI_API_KEY}}", redact = true }
OPENROUTER_API_KEY = { value = "{{vars.OPENROUTER_API_KEY}}", redact = true }

[tools]
ruby = "3.4.8"
```

The sandbox is its own `PROJECT_ROOT_PATH` (via `{{ config_root }}`).
The bin path is hardcoded to the resolved worktree — it varies per worktree but is fixed once written.

### 4. Trust mise config

```bash
cd "$SANDBOX_DIR"
mise trust
```

Mise requires explicit trust for config files in new directories. Without this step,
mise will refuse to load the toml and tools won't be on PATH.

### 5. Verify tooling

```bash
cd "$SANDBOX_DIR"
ace-b36ts --help
```

Expected: help output showing subcommands and flags. Non-zero exit = setup failure.

## Outputs

- `sandbox/` directory with git repo initialized
- `sandbox/mise.toml` with correct PATH configuration
- `sandbox/results/{1..8}/` empty directories ready for artifacts
- `sandbox/reports/` empty directory for prompts and outputs

## Gitignore

The `sandbox/` directory should be gitignored. Add to `.gitignore` in the experiment directory:

```
sandbox/
```
