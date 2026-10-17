# ACE Configuration Directory

This directory contains the project-owned configuration for the ACE (Agentic
Coding Environment) development system. Files here are tracked in Git; machine
or user overrides live under `~/.ace/`.

The canonical state-owner map and local flow are in
[docs/lab-flow.md](../docs/lab-flow.md). This directory holds configuration
only; it is not a state store.

## Directory Structure

```
.ace/
├── assign/                # ace-assign (config.yml)
├── bundle/                # ace-bundle (config.yml, presets/)
├── core/                  # ace-support-core (settings.yml)
├── demo/                  # ace-demo (fixtures/, tapes/)
├── docs/                  # ace-docs
├── e2e-runner/            # ace-test-runner-e2e
├── git/                   # ace-git, ace-git-commit, ace-git-worktree
├── git-secrets/           # ace-git-secrets (config.yml, gitleaks.toml)
├── handbook/              # ace-handbook (sync providers)
├── lint/                  # ace-lint (kramdown.yml)
├── llm/                   # ace-llm (providers/, presets/)
├── nav/                   # ace-nav (protocols/)
├── prompt-prep/           # ace-prompt-prep
├── review/                # ace-review (config.yml, presets/)
├── task/                  # ace-task (config.yml; task root and special folders)
├── test/                  # ace-test-runner (runner.yml, suite.yml)
└── tmux/                  # ace-tmux (panes/, windows/)
```

## State owners (not config)

Task and workflow state is never stored in `.ace/`. The owners are:

| Information | Write location | Owner |
|---|---|---|
| Project task specs and progress | `.ace-tasks/` | `ace-task` |
| Private overseer task list | `.ace-tasks/_overseer/` (gitignored) | overseer via `ace-task --in _overseer` |
| Assignment plan and step reports | `.ace-local/assign/` | `ace-assign` |
| Coworker run configuration (L3) | `.ace-local/coworker/` | reserved in L3 |
| HITL agent events | `.ace-local/hitl/` | `ace-hitl` |
| Project task worktree | `.ace-wt/<task>/` | `ace-git-worktree` |

The lab does not add a journal, queue engine, authority/admission layer,
listener/daemon, topology registry, or extra state cache. tmux, Herdr, and
Hermes are transports only.

## Configuration Cascade

Configuration resolves with nearest-wins precedence:

1. CLI flags for this invocation
2. Project `.ace/` (this directory, committed)
3. User `~/.ace/`
4. Gem `.ace-defaults/` (shipped defaults)
5. Environment variables `ACE_NAMESPACE_KEY` override all

```ruby
resolver = Ace::Support::Config.create
config = resolver.resolve_namespace("git", filename: "commit")
```

```bash
# Example: project override for commit generation
# .ace/git/commit.yml
model: "role:commit"
```

## Namespace Conventions

Each `ace-*` gem owns its configuration namespace under `.ace/<namespace>/`.
Overrides are explicit; there is no hidden per-gem fallback file.

| Gem | Namespace | Main file(s) |
|---|---|---|
| ace-support-core | `core/` | `settings.yml` |
| ace-assign | `assign/` | `config.yml` |
| ace-bundle | `bundle/` | `config.yml`, `presets/` |
| ace-demo | `demo/` | `fixtures/`, `tapes/` |
| ace-docs | `docs/` | `config.yml` |
| ace-git | `git/` | `config.yml`, `commit.yml`, `worktree.yml` |
| ace-git-secrets | `git-secrets/` | `config.yml`, `gitleaks.toml` |
| ace-handbook | `handbook/` | `config.yml` |
| ace-lint | `lint/` | `kramdown.yml` |
| ace-llm | `llm/` | `config.yml`, `providers/`, `presets/` |
| ace-nav | `nav/` | `protocols/` |
| ace-prompt-prep | `prompt-prep/` | `config.yml` |
| ace-review | `review/` | `config.yml`, `presets/` |
| ace-task | `task/` | `config.yml` |
| ace-test-runner | `test/` | `runner.yml`, `suite.yml` |
| ace-test-runner-e2e | `e2e-runner/` | `config.yml` |
| ace-tmux | `tmux/` | `panes/`, `windows/` |

## Task root and the private `_overseer` folder

`ace-task` roots tasks at `root_dir` in `.ace/task/config.yml` (`.ace-tasks/`):

```yaml
task:
  root_dir: .ace-tasks
```

The private overseer list is an ordinary special folder inside that same task
tree: `.ace-tasks/_overseer/`. It is gitignored, so it never enters commits, and
`ace-task` treats it like any other special folder:

- `ace-task list --in _overseer` narrows the shared list to private tasks,
  including their private archive history.
- The default `ace-task list` shows project root tasks and active `_overseer`
  tasks together; archived private families live in
  `.ace-tasks/_overseer/_archive/` and stay inside the gitignored tree.

## Usage

```bash
bin/ace-task status            # project task view (.ace-tasks/)
bin/ace-task list --in _overseer
bin/ace-assign status          # assignment plan (.ace-local/assign/)
bin/ace-review --help          # review config and presets
bin/ace-test-suite             # root suite configuration
```

## Best practices

1. Keep project configuration in version control.
2. Document custom settings inline in the YAML file.
3. Start minimal; override only what differs from shipped defaults.
4. Verify changes with a dry-run option where available.
5. Do not mix namespaces or put task/HITL/assignment state in `.ace/`.
