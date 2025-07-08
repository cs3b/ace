# Coding Agent Tools - Development Tools Reference

## Main Cheat-sheet

| Tool | Purpose | Key Flags |
|------|---------|-----------|
| `code-review` | Interactive code review tool | `--interactive`, `--batch` |
| `code-review-prepare` | Review preparation tool | `--context`, `--diff-only` |
| `code-review-synthesize` | Review synthesis tool | `--format`, `--include-recommendations` |
| `generate-review-prompt` | Code review prompt generator | `--context-lines`, `--detailed` |
| `git-add` | Enhanced git add | `--interactive`, `--pattern` |
| `git-commit` | Enhanced git commit | `--guided`, `--auto-format` |
| `git-diff` | Enhanced git diff | `--staged`, `--stat` |
| `git-fetch` | Enhanced git fetch | `--all-repos`, `--report` |
| `git-log` | Enhanced git log | `--enhanced`, `--project-context` |
| `git-pull` | Enhanced git pull | `--resolve-conflicts`, `--all-repos` |
| `git-push` | Enhanced git push | `--safe`, `--all-repos` |
| `git-status` | Enhanced git status | `--project-context`, `--all-repos` |
| `handbook` | Development handbook access | `sync-templates` |
| `llm-query` | Unified LLM query interface | `--model`, `--output` |
| `nav-ls` | Enhanced directory listing | `--project-context`, `--filter` |
| `nav-path` | Intelligent path navigation | `task-new`, `file` |
| `nav-tree` | Enhanced project tree | `--project-structure`, `--filter` |
| `reflection-synthesize` | Reflection report generator | `--session`, `--focus` |
| `release-manager` | Release management tool | `current`, `report` |
| `task-manager` | Project task management | `next`, `all` |

## Persona Cheat-sheets

### AI Agent
| Tool | Purpose | Key Flags |
|------|---------|-----------|
| `llm-query` | Query AI models | `--model`, `--output` |
| `nav-path` | Navigate project paths | `task-new`, `file` |
| `release-manager` | Manage releases | `current`, `report` |
| `task-manager` | Manage tasks | `next`, `all` |

### Human Developer
| Tool | Purpose | Key Flags |
|------|---------|-----------|
| `code-review` | Review code interactively | `--interactive`, `--batch` |
| `handbook` | Access development guides | `sync-templates` |
| `reflection-synthesize` | Generate session reports | `--session`, `--focus` |

### Git Power-User
| Tool | Purpose | Key Flags |
|------|---------|-----------|
| `git-add` | Enhanced file staging | `--interactive`, `--pattern` |
| `git-commit` | Smart commit tool | `--guided`, `--auto-format` |
| `git-diff` | Advanced diff viewer | `--staged`, `--stat` |
| `git-status` | Multi-repo status | `--all-repos`, `--project-context` |

### Release Manager
| Tool | Purpose | Key Flags |
|------|---------|-----------|
| `release-manager` | Release coordination | `current`, `report` |
| `task-manager` | Track deliverables | `next`, `all` |

## Setup Requirements

### Dependencies
- **Ruby** >= 3.2.0
- **Bundler** for dependency management  
- **Git** CLI for repository operations
- **dev-handbook** submodule for task management utilities

### Environment Setup
```bash
# Initial setup (run from dev-tools/ directory)
cd dev-tools && bundle install

# Load Ruby console with gem loaded (run from dev-tools/ directory)
cd dev-tools && bundle exec irb -r ./lib/coding_agent_tools
```

## Gem Executables

### `llm-query` – Unified LLM query interface
<details><summary>Details</summary>

```bash
llm-query [PROVIDER:MODEL] [PROMPT] [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `--model` | Specify AI model | Provider default |
| `--output` | Output file path | stdout |
| `--system` | System instruction | None |
| `--temperature` | Response randomness | 0.7 |

**Examples**
```bash
llm-query google:gemini-2.5-flash "What is Ruby?"
llm-query anthropic "Explain ATOM architecture" --output review.json
llm-query csonet "Write a function" --system "You are a Ruby expert"
```
</details>


### `task-manager` – Project task management
<details><summary>Details</summary>

```bash
task-manager [COMMAND] [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `next` | Show next actionable task | N/A |
| `all` | List all tasks | N/A |
| `recent` | Show recently modified tasks | N/A |
| `generate-id` | Generate new task ID | N/A |

**Examples**
```bash
task-manager next
task-manager all
task-manager recent
```
</details>

### `generate-review-prompt` – Code review prompt generator
<details><summary>Details</summary>

```bash
generate-review-prompt [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `--context-lines` | Context lines around changes | `3` |
| `--detailed` | Include detailed analysis | `false` |
| `--arch-focus` | Architectural considerations | `false` |

**Examples**
```bash
generate-review-prompt --context-lines 5
generate-review-prompt --detailed --arch-focus
```
</details>

### `code-review` – Interactive code review tool
<details><summary>Details</summary>

```bash
code-review [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `--interactive` | Interactive review mode | `false` |
| `--batch` | Batch processing mode | `false` |
| `--output-format` | Output format | `text` |

**Examples**
```bash
code-review --interactive
code-review --batch --output-format json
```
</details>

### `code-review-prepare` – Review preparation tool
<details><summary>Details</summary>

```bash
code-review-prepare [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `--context` | Context level | `basic` |
| `--diff-only` | Focus on diff only | `false` |

**Examples**
```bash
code-review-prepare --context full
code-review-prepare --diff-only
```
</details>

### `code-review-synthesize` – Review synthesis tool
<details><summary>Details</summary>

```bash
code-review-synthesize [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `--format` | Output format | `text` |
| `--include-recommendations` | Include recommendations | `false` |

**Examples**
```bash
code-review-synthesize --format report
code-review-synthesize --include-recommendations
```
</details>

### `reflection-synthesize` – Reflection report generator
<details><summary>Details</summary>

```bash
reflection-synthesize [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `--session` | Session identifier | `current` |
| `--focus` | Focus areas | All areas |

**Examples**
```bash
reflection-synthesize --session current
reflection-synthesize --focus architecture,testing
```
</details>

### `git-add` – Enhanced git add
<details><summary>Details</summary>

```bash
git-add [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `--interactive` | Interactive file selection | `false` |
| `--pattern` | Pattern matching | None |

**Examples**
```bash
git-add --interactive
git-add --pattern "*.rb"
```
</details>

### `git-commit` – Enhanced git commit
<details><summary>Details</summary>

```bash
git-commit [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `--guided` | Guided message generation | `false` |
| `--auto-format` | Automatic formatting | `false` |

**Examples**
```bash
git-commit --guided
git-commit --auto-format
```
</details>

### `git-diff` – Enhanced git diff
<details><summary>Details</summary>

```bash
git-diff [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `--staged` | Show staged changes only | `false` |
| `--name-only` | Show file names only | `false` |
| `--stat` | Show diffstat summary | `false` |
| `--repository` | Specific repository context | Current |

**Examples**
```bash
git-diff --staged
git-diff --stat
git-diff --repository dev-tools
```
</details>

### `git-fetch` – Enhanced git fetch
<details><summary>Details</summary>

```bash
git-fetch [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `--all-repos` | Fetch all repositories | `false` |
| `--report` | Status reporting | `false` |

**Examples**
```bash
git-fetch --all-repos
git-fetch --report
```
</details>

### `git-log` – Enhanced git log
<details><summary>Details</summary>

```bash
git-log [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `--enhanced` | Enhanced formatting | `false` |
| `--project-context` | Project context | `false` |

**Examples**
```bash
git-log --enhanced
git-log --project-context
```
</details>

### `git-pull` – Enhanced git pull
<details><summary>Details</summary>

```bash
git-pull [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `--resolve-conflicts` | Conflict resolution | `false` |
| `--all-repos` | All repositories | `false` |

**Examples**
```bash
git-pull --resolve-conflicts
git-pull --all-repos
```
</details>

### `git-push` – Enhanced git push
<details><summary>Details</summary>

```bash
git-push [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `--safe` | Safety checks | `false` |
| `--all-repos` | All repositories | `false` |

**Examples**
```bash
git-push --safe
git-push --all-repos
```
</details>

### `git-status` – Enhanced git status
<details><summary>Details</summary>

```bash
git-status [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `--project-context` | Project context | `false` |
| `--all-repos` | All repositories | `false` |

**Examples**
```bash
git-status --project-context
git-status --all-repos
```
</details>

### `nav-ls` – Enhanced directory listing
<details><summary>Details</summary>

```bash
nav-ls [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `--project-context` | Project context | `false` |
| `--filter` | File pattern filter | None |

**Examples**
```bash
nav-ls --project-context
nav-ls --filter "*.rb"
```
</details>

### `nav-path` – Intelligent path navigation
<details><summary>Details</summary>

```bash
nav-path [COMMAND] [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `task-new` | Generate new task path | N/A |
| `task` | Resolve task by ID | N/A |
| `file` | Resolve file path | N/A |
| `--title` | Title for new items | Required |

**Examples**
```bash
nav-path task-new --title "Feature Name"
nav-path task 42
nav-path file README
```
</details>

### `nav-tree` – Enhanced project tree
<details><summary>Details</summary>

```bash
nav-tree [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `--project-structure` | Project structure aware | `false` |
| `--filter` | Content filter | None |

**Examples**
```bash
nav-tree --project-structure
nav-tree --filter source
```
</details>

### `handbook` – Development handbook access
<details><summary>Details</summary>

```bash
handbook [COMMAND]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `sync-templates` | Sync template content | N/A |

**Examples**
```bash
handbook sync-templates
```
</details>

### `release-manager` – Release management tool
<details><summary>Details</summary>

```bash
release-manager [COMMAND] [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `current` | Show current release | N/A |
| `report` | Generate reports | N/A |
| `--format` | Report format | `standard` |

**Examples**
```bash
release-manager current
release-manager report --format detailed
```
</details>

## Tool Categories

### By Function
- **Code Review**: `code-review`, `code-review-prepare`, `code-review-synthesize`, `generate-review-prompt`
- **Git Operations**: `git-add`, `git-commit`, `git-diff`, `git-fetch`, `git-log`, `git-pull`, `git-push`, `git-status`
- **LLM Integration**: `llm-query`
- **Navigation & Documentation**: `handbook`, `nav-ls`, `nav-path`, `nav-tree`
- **Project Management**: `release-manager`, `task-manager`
- **Reflection & Analysis**: `reflection-synthesize`

### By Persona
- **AI Agent**: `llm-query`, `nav-path`, `release-manager`, `task-manager`
- **Human Developer**: `code-review`, `handbook`, `reflection-synthesize`
- **Git Power-User**: `git-add`, `git-commit`, `git-diff`, `git-status`
- **Release Manager**: `release-manager`, `task-manager`

## Common Workflows

### AI Agent Workflow
```bash
# Find next task and navigate
task-manager next
nav-path task 42

# Query AI for implementation guidance
llm-query google "How to implement feature X?"

# Generate new task when needed
nav-path task-new --title "Implement feature X"
```

### Human Developer Workflow
```bash
# Sync documentation and review code
handbook sync-templates
code-review --interactive

# Track recent work and generate reflection
task-manager recent
reflection-synthesize --session current
```

### Git Power-User Workflow
```bash
# Enhanced git operations across repositories
git-status --all-repos
git-diff --stat
git-commit --guided
git-push --safe
```

## Notes

- All tools available directly by name via fish integration
- Use `tool-name --help` for detailed usage information
- Git wrappers provide enhanced functionality over standard git commands
- LLM integration includes intelligent caching and cost tracking

---

*For the most up-to-date information, run individual tools with `--help` flag.*