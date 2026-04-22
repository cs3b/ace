# ACE Quick-Start First-Use Setup - Draft Usage

## API Surface

- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [x] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Minimal Setup

**Goal**: A first-time user installs the smallest useful ACE setup for task specs, bundled handbook resources, LLM access, and one agent integration.

```bash
bundle add --group "development, test" \
  ace-task ace-bundle ace-handbook ace-llm ace-llm-providers-cli \
  ace-handbook-integration-codex
bundle install
bundle exec ace-config init
bundle exec ace-handbook sync
bundle exec ace-llm --list-providers
bundle exec ace-bundle project
```

## Expected Output

The docs explain that this path creates or updates project-local ACE config and agent guidance, including `.ace/`, `.codex/skills/`, `AGENTS.md`, `CLAUDE.md`, `Gemfile`, and `Gemfile.lock` when applicable.

### Scenario 2: Full-Stack Setup

**Goal**: A power user installs the complete ACE workflow stack for planning, assignment orchestration, review, testing, docs, retrospectives, demos, and git helpers.

```bash
bundle add --group "development, test" \
  ace-idea ace-task ace-sim \
  ace-overseer ace-assign ace-git-worktree ace-tmux \
  ace-bundle ace-handbook ace-search ace-docs ace-llm ace-llm-providers-cli \
  ace-review ace-lint ace-test-runner ace-test-runner-e2e ace-retro ace-demo \
  ace-git-commit ace-git-secrets ace-git \
  ace-handbook-integration-claude ace-handbook-integration-codex
bundle install
bundle exec ace-config init
bundle exec ace-handbook sync
bundle exec ace-config doctor
```

## Expected Output

The docs identify this as the larger path and explain that the generated file set can be large because ACE stores config, tasks, workflows, skills, and guidance in the repository.

### Scenario 3: First Setup Commit

**Goal**: A user commits ACE setup files deterministically without depending on provider-backed commit message generation.

```bash
bundle exec ace-git-commit --only-staged --no-split -m "chore: set up ace tooling"
```

## Expected Output

The docs explain that `--only-staged` commits the current index, `--no-split` keeps the initial setup snapshot in one commit, and `-m` avoids LLM-backed message generation.

### Scenario 4: Setup Readiness

**Goal**: A user distinguishes provider discovery from actual readiness before running LLM-backed workflows.

```bash
bundle exec ace-llm --list-providers
bundle exec ace-config doctor
bundle exec ace-config doctor --no-probe
```

## Expected Output

Provider discovery lists available providers and setup hints. Setup doctor reports readiness for generated files, ignored local artifacts, bundled gems, and provider execution readiness according to the runtime contract in task `8rl.t.k5a.2`.

## Notes for Implementer

Full usage documentation should be completed during work-on-task with `wfi://docs/update-usage`. Keep issue #299 documentation work coordinated with issue #298 runtime readiness tasks instead of redefining the same runtime behavior twice.
