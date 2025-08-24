# Coding Agent Tools - Development Tools Reference

## Main Cheat-sheet

| Tool | Purpose | Key Flags |
|------|---------|-----------|
| **`search`** | **Unified intelligent search** | **`--files`, `--preset`, `--fzf`** |
| `code-review` | Preset-based code review | `--preset`, `--context` |
| `code-review-synthesize` | Review synthesis tool | `--format` |
| `create-path` | Create files/directories | `--force`, `--content` |
| `git-add` | Enhanced git add | `--patch`, `--all` |
| `git-commit` | Enhanced git commit | `--intention`, `--no-edit` |
| `git-fetch` | Enhanced git fetch | `--all`, `--prune` |
| `git-log` | Enhanced git log | `--oneline`, `--graph` |
| `git-pull` | Enhanced git pull | `--rebase`, `--ff-only` |
| `git-push` | Enhanced git push | `--force`, `--dry-run` |
| `git-status` | Enhanced git status | `--verbose`, `--short` |
| `git-tag` | Enhanced git tag | `--annotate`, `--delete` |
| `handbook` | Development handbook access | `sync-templates` |
| `llm-query` | Unified LLM query | `--model`, `--output` |
| `nav-ls` | Enhanced directory listing | `--long`, `--all` |
| `nav-path` | Intelligent path navigation | `task`, `file` |
| `nav-tree` | Enhanced project tree | `--context`, `--depth` |
| `reflection-synthesize` | Reflection report generator | `--session`, `--focus` |
| `release-manager` | Release management | `current`, `report` |
| `task-manager` | Project task management | `--filter`, `--sort` |

## Persona Cheat-sheets

### AI Agent

| Tool | Purpose | Key Flags |
|------|---------|-----------|
| `task-manager` | Manage tasks | `--filter`, `--sort` |
| `llm-query` | Query AI models | `--model`, `--output` |
| `nav-path` | Navigate paths | `task`, `file` |
| `release-manager` | Manage releases | `current`, `report` |

### Human Developer

| Tool | Purpose | Key Flags |
|------|---------|-----------|
| `code-review` | Review code | `--preset`, `--model` |
| `handbook` | Access guides | `sync-templates` |
| `reflection-synthesize` | Generate reports | `--session`, `--focus` |

### Git Power-User

| Tool | Purpose | Key Flags |
|------|---------|-----------|
| `git-add` | Stage files | `--patch`, `--all` |
| `git-commit` | Smart commit | `--intention` |
| `git-status` | Check status | `--verbose` |
| `git-tag` | Manage tags | `--annotate` |

### Release Manager

| Tool | Purpose | Key Flags |
|------|---------|-----------|
| `release-manager` | Coordinate releases | `current`, `report` |
| `task-manager` | Track deliverables | `--filter`, `--sort` |

## Setup Requirements

### Dependencies

* **Ruby** >= 3.2.0
* **Bundler** for dependency management
* **Git** CLI for repository operations
* **dev-handbook** submodule for task management utilities

### Environment Setup

```bash
# Initial setup (run from dev-tools/ directory)
cd dev-tools && bundle install

# Load Ruby console with gem loaded
cd dev-tools && bundle exec irb -r ./lib/coding_agent_tools
```

## Gem Executables

### `search` – Fast unified search for files and content
<details><summary>Details</summary>

```bash
search [PATTERN] [OPTIONS]
```

**Key flags:** `--files` (file search), `--preset NAME` (use preset), `--fzf` (interactive)

**Example:**
```bash
search "TODO" --preset todo  # Find all TODO comments
```
</details>

### `code-review` – Preset-based code review with context integration
<details><summary>Details</summary>

```bash
code-review [OPTIONS]
```

**Key flags:** `--preset NAME` (review preset), `--context FILE` (context file)

**Example:**
```bash
code-review --preset architecture  # Review architecture changes
```
</details>

### `code-review-synthesize` – Synthesize code review results
<details><summary>Details</summary>

```bash
code-review-synthesize [OPTIONS]
```

**Key flags:** `--format FORMAT` (output format)

**Example:**
```bash
code-review-synthesize --format markdown  # Generate markdown report
```
</details>

### `create-path` – Create files/directories with templates
<details><summary>Details</summary>

```bash
create-path PATH [OPTIONS]
```

**Key flags:** `--force` (overwrite), `--content TEXT` (file content)

**Example:**
```bash
create-path docs/new-guide.md --content "# Guide"  # Create with content
```
</details>

### `git-add` – Enhanced git add with smart staging
<details><summary>Details</summary>

```bash
git-add [FILES] [OPTIONS]
```

**Key flags:** `--patch` (interactive), `--all` (all changes)

**Example:**
```bash
git-add --patch  # Interactive staging
```
</details>

### `git-commit` – Enhanced git commit with intentions
<details><summary>Details</summary>

```bash
git-commit [OPTIONS]
```

**Key flags:** `--intention TYPE` (commit type), `--no-edit` (skip editor)

**Example:**
```bash
git-commit --intention fix  # Create fix commit
```
</details>

### `git-fetch` – Enhanced git fetch
<details><summary>Details</summary>

```bash
git-fetch [OPTIONS]
```

**Key flags:** `--all` (all remotes), `--prune` (remove deleted)

**Example:**
```bash
git-fetch --all --prune  # Fetch all and cleanup
```
</details>

### `git-log` – Enhanced git log display
<details><summary>Details</summary>

```bash
git-log [OPTIONS]
```

**Key flags:** `--oneline` (compact), `--graph` (show graph)

**Example:**
```bash
git-log --oneline --graph  # Visual commit history
```
</details>

### `git-pull` – Enhanced git pull
<details><summary>Details</summary>

```bash
git-pull [OPTIONS]
```

**Key flags:** `--rebase` (rebase instead), `--ff-only` (fast-forward only)

**Example:**
```bash
git-pull --rebase  # Pull with rebase
```
</details>

### `git-push` – Enhanced git push
<details><summary>Details</summary>

```bash
git-push [OPTIONS]
```

**Key flags:** `--force` (force push), `--dry-run` (preview)

**Example:**
```bash
git-push --dry-run  # Preview push changes
```
</details>

### `git-status` – Enhanced git status
<details><summary>Details</summary>

```bash
git-status [OPTIONS]
```

**Key flags:** `--verbose` (detailed), `--short` (compact)

**Example:**
```bash
git-status --short  # Compact status view
```
</details>

### `git-tag` – Enhanced git tag management
<details><summary>Details</summary>

```bash
git-tag [TAGNAME] [OPTIONS]
```

**Key flags:** `--annotate` (annotated tag), `--delete` (delete tag)

**Example:**
```bash
git-tag v1.0.0 --annotate  # Create annotated tag
```
</details>

### `handbook` – Development handbook access
<details><summary>Details</summary>

```bash
handbook [COMMAND] [OPTIONS]
```

**Key flags:** `sync-templates` (sync templates)

**Example:**
```bash
handbook sync-templates  # Sync project templates
```
</details>

### `llm-query` – Unified LLM query interface
<details><summary>Details</summary>

```bash
llm-query PROMPT [OPTIONS]
```

**Key flags:** `--model NAME` (model selection), `--output FILE` (save output)

**Examples:**
```bash
llm-query "Explain this code" --model gpt4     # Query with GPT-4
llm-query "Review this code" codex:o3          # Query with Codex o3
llm-query "Hello world" codex:o3-mini         # Query with Codex o3-mini
llm-query "Local help" codexoss:llama3        # Query with Codex OSS (Ollama)
```
</details>

### `nav-ls` – Enhanced directory listing
<details><summary>Details</summary>

```bash
nav-ls [PATH] [OPTIONS]
```

**Key flags:** `--long` (detailed), `--all` (show hidden)

**Example:**
```bash
nav-ls --long --all  # Detailed listing with hidden files
```
</details>

### `nav-path` – Intelligent path navigation
<details><summary>Details</summary>

```bash
nav-path COMMAND [ARGS]
```

**Key flags:** `task` (find task), `file` (find file)

**Example:**
```bash
nav-path file blueprint  # Find blueprint file
```
</details>

### `nav-tree` – Enhanced project tree view
<details><summary>Details</summary>

```bash
nav-tree [PATH] [OPTIONS]
```

**Key flags:** `--context` (with context), `--depth N` (tree depth)

**Example:**
```bash
nav-tree --depth 2  # Show 2-level tree
```
</details>

### `reflection-synthesize` – Generate reflection reports
<details><summary>Details</summary>

```bash
reflection-synthesize [OPTIONS]
```

**Key flags:** `--session ID` (session), `--focus AREA` (focus area)

**Example:**
```bash
reflection-synthesize --session today  # Today's reflection
```
</details>

### `release-manager` – Release management tool
<details><summary>Details</summary>

```bash
release-manager COMMAND [OPTIONS]
```

**Key flags:** `current` (current release), `report` (generate report)

**Example:**
```bash
release-manager current  # Show current release
```
</details>

### `task-manager` – Project task management
<details><summary>Details</summary>

```bash
task-manager [COMMAND] [OPTIONS]
```

**Key flags:** `--filter STATUS` (filter tasks), `--sort FIELD` (sort by)

**Example:**
```bash
task-manager --filter pending  # Show pending tasks
```
</details>

## Workflow Integration

### Finding Files
```bash
search "*.rb" --files  # Find Ruby files
nav-path file spec  # Navigate to spec file
```

### Managing Tasks
```bash
task-manager --filter pending  # List pending tasks
nav-path task 001  # Navigate to task
```

### Git Workflow
```bash
git-status --short  # Quick status check
git-add --patch  # Interactive staging
git-commit --intention feat  # Feature commit
```

### Code Review
```bash
code-review --preset security  # Security review
code-review-synthesize  # Generate report
```