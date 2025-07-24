# Coding Agent Tools - Development Tools Reference   {#coding-agent-tools---development-tools-reference}

## Main Cheat-sheet   {#main-cheat-sheet}

| Tool | Purpose | Key Flags |
|----------
| `code-review` | Interactive code review tool | `--interactive`, `--batch` |
| `code-review-prepare` | Review preparation tool | `--context`, `--diff-only` |
| `code-review-synthesize` | Review synthesis tool | `--format`, `--include-recommendations` |
| `git-add` | Enhanced git add | `--patch`, `--all` |
| `git-commit` | Enhanced git commit | `--intention`, `--no-edit` |
| `git-diff` | Enhanced git diff | `--staged`, `--stat` |
| `git-fetch` | Enhanced git fetch | `--all`, `--prune` |
| `git-log` | Enhanced git log | `--oneline`, `--graph` |
| `git-pull` | Enhanced git pull | `--rebase`, `--ff-only` |
| `git-push` | Enhanced git push | `--force`, `--dry-run` |
| `git-status` | Enhanced git status | `--verbose`, `--short` |
| `handbook` | Development handbook access | `sync-templates` |
| `llm-query` | Unified LLM query interface | `--model`, `--output` |
| `nav-ls` | Enhanced directory listing | `--long`, `--all` |
| `nav-path` | Intelligent path navigation | `task-new`, `file` |
| `nav-tree` | Enhanced project tree | `--context`, `--depth` |
| `reflection-synthesize` | Reflection report generator | `--session`, `--focus` |
| `release-manager` | Release management tool | `current`, `report` |
| `task-manager` | Project task management | `next`, `all` |

**💡 Pro Tip**: For file location, always use `nav-path file <filename>` instead of `find` or `ls` commands. It's intelligent, fast, and works with partial names (e.g., `nav-path file blueprint` finds `docs/blueprint.md`).

## Persona Cheat-sheets   {#persona-cheat-sheets}

### AI Agent   {#ai-agent}

\| Tool \| Purpose \| Key Flags \| \|------\|---------\|-----------\| \|
`llm-query` \| Query AI models \| `--model`, `--output` \| \| `nav-path`
\| Navigate project paths \| `task-new`, `file` \| \| `release-manager`
\| Manage releases \| `current`, `report` \| \| `task-manager` \| Manage
tasks \| `next`, `all` \|

### Human Developer   {#human-developer}

\| Tool \| Purpose \| Key Flags \| \|------\|---------\|-----------\| \|
`code-review` \| Review code interactively \| `--interactive`, `--batch`
\| \| `handbook` \| Access development guides \| `sync-templates` \| \|
`reflection-synthesize` \| Generate session reports \| `--session`,
`--focus` \|

### Git Power-User   {#git-power-user}

\| Tool \| Purpose \| Key Flags \| \|------\|---------\|-----------\| \|
`git-add` \| Enhanced file staging \| `--patch`, `--all` \| \|
`git-commit` \| Smart commit tool \| `--intention`, `--no-edit` \| \|
`git-diff` \| Advanced diff viewer \| `--staged`, `--stat` \| \|
`git-status` \| Multi-repo status \| `--verbose`, `--short` \|

### Release Manager   {#release-manager}

\| Tool \| Purpose \| Key Flags \| \|------\|---------\|-----------\| \|
`release-manager` \| Release coordination \| `current`, `report` \| \|
`task-manager` \| Track deliverables \| `next`, `all` \|

## Setup Requirements   {#setup-requirements}

### Dependencies   {#dependencies}

* **Ruby** >= 3.2.0
* **Bundler** for dependency management
* **Git** CLI for repository operations
* **dev-handbook** submodule for task management utilities

### Environment Setup   {#environment-setup}

    # Initial setup (run from dev-tools/ directory)
    cd dev-tools && bundle install
    
    # Load Ruby console with gem loaded (run from dev-tools/ directory)
    cd dev-tools && bundle exec irb -r ./lib/coding_agent_tools
{: .language-bash}

## Gem Executables   {#gem-executables}

### `llm-query` – Unified LLM query interface   {#llm-query--unified-llm-query-interface}

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

### `task-manager` – Project task management   {#task-manager--project-task-management}

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

### `code-review` – Interactive code review tool   {#code-review--interactive-code-review-tool}

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

### `code-review-prepare` – Review preparation tool   {#code-review-prepare--review-preparation-tool}

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

### `code-review-synthesize` – Review synthesis tool   {#code-review-synthesize--review-synthesis-tool}

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

### `reflection-synthesize` – Reflection report generator   {#reflection-synthesize--reflection-report-generator}

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

### `git-add` – Enhanced git add   {#git-add--enhanced-git-add}

<details><summary>Details</summary>

```bash
git-add [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `--patch` | Interactively choose hunks to add | `false` |
| `--all` | Add all changes (new, modified, deleted) | `false` |
| `--update` | Add only modified and deleted files | `false` |
| `--repository` | Specify repository context | Current |

**Examples**
```bash
git-add --patch
git-add --all --repository dev-tools
```
</details>

### `git-commit` – Enhanced git commit   {#git-commit--enhanced-git-commit}

<details><summary>Details</summary>

```bash
git-commit [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `--intention` | Intention context for commit message | None |
| `--no-edit` | Skip editor and commit directly | `false` |
| `--message` | Use provided message instead of LLM | None |
| `--all` | Stage all changes before committing | `false` |
| `--model` | Specify LLM model | Default model |

**Examples**
```bash
git-commit --intention "fix typo"
git-commit --no-edit --all
```
</details>

### `git-diff` – Enhanced git diff   {#git-diff--enhanced-git-diff}

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

### `git-fetch` – Enhanced git fetch   {#git-fetch--enhanced-git-fetch}

<details><summary>Details</summary>

```bash
git-fetch [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `--all` | Fetch all remotes | `false` |
| `--prune` | Remove stale remote references | `false` |
| `--tags` | Fetch tags | `false` |
| `--repository` | Specify repository context | Current |

**Examples**
```bash
git-fetch --all --prune
git-fetch --tags --repository dev-tools
```
</details>

### `git-log` – Enhanced git log   {#git-log--enhanced-git-log}

<details><summary>Details</summary>

```bash
git-log [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `--oneline` | Show commits in oneline format | `false` |
| `--graph` | Show commit graph | `false` |
| `--since` | Show commits since date | None |
| `--author` | Show commits by specific author | None |

**Examples**
```bash
git-log --oneline
git-log --graph --since "1 week ago"
```
</details>

### `git-pull` – Enhanced git pull   {#git-pull--enhanced-git-pull}

<details><summary>Details</summary>

```bash
git-pull [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `--rebase` | Rebase instead of merge | `false` |
| `--ff-only` | Only allow fast-forward merges | `false` |
| `--no-commit` | Don't commit automatic merge | `false` |
| `--strategy` | Merge strategy to use | Default |

**Examples**
```bash
git-pull --rebase
git-pull --ff-only --repository dev-tools
```
</details>

### `git-push` – Enhanced git push   {#git-push--enhanced-git-push}

<details><summary>Details</summary>

```bash
git-push [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `--force` | Force push (use with caution) | `false` |
| `--dry-run` | Show what would be pushed | `false` |
| `--set-upstream` | Set upstream tracking | `false` |
| `--tags` | Push tags along with commits | `false` |

**Examples**
```bash
git-push --dry-run
git-push --set-upstream --repository dev-tools
```
</details>

### `git-status` – Enhanced git status   {#git-status--enhanced-git-status}

<details><summary>Details</summary>

```bash
git-status [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `--verbose` | Show detailed status information | `false` |
| `--short` | Give output in short format | `false` |
| `--repository` | Specify repository context | Current |
| `--porcelain` | Give output in porcelain format | `false` |

**Examples**
```bash
git-status --verbose
git-status --short --repository dev-tools
```
</details>

### `nav-ls` – Enhanced directory listing   {#nav-ls--enhanced-directory-listing}

<details><summary>Details</summary>

```bash
nav-ls [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `--long` | Use long format (ls -l) | `false` |
| `--all` | Show hidden files (ls -a) | `false` |
| `--autocorrect` | Enable path autocorrection | `true` |

**Examples**
```bash
nav-ls --long docs/
nav-ls --all --long src/
```
</details>

### `nav-path` – Intelligent path navigation   {#nav-path--intelligent-path-navigation}

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
# Task management
nav-path task-new --title "Feature Name"
nav-path task 42

# File location (PREFERRED over find/ls commands)
nav-path file README          # Finds README.md, README.txt, etc.
nav-path file blueprint       # Finds docs/blueprint.md
nav-path file tools           # Finds docs/tools.md, dev-tools/docs/tools.md
nav-path file config          # Finds .coding-agent/path.yml, config files

# Instead of: find . -name "*blueprint*" -type f
# Use:        nav-path file blueprint
```

**🎯 Recommended Usage**: Always use `nav-path file <filename>` instead of `find`, `ls`, or manual directory searching. It's faster, smarter, and respects project structure.

**Configuration**: Skip patterns can be customized in `.coding-agent/path.yml`:

```yaml
security:
  forbidden_patterns:
    - "**/.git/**"              # Git internals (version control)
    - "**/node_modules/**"      # NPM dependencies
    - "**/coverage/**"          # Test coverage files
    - "**/tmp/**"               # Temporary files
    - "**/*.log"                # Log files
    - "**/.DS_Store"            # macOS system files
    - "**/Gemfile.lock"         # Ruby dependency lock files
    - "**/package-lock.json"    # Node.js dependency lock files
    - "**/.*"                   # All other dot files and directories
    - ".*"                      # Top-level dot files
```

These patterns use glob syntax and prevent nav-path from accessing specified directories and files.

</details>

### `nav-tree` – Enhanced project tree   {#nav-tree--enhanced-project-tree}

<details><summary>Details</summary>

```bash
nav-tree [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `--context` | Tree context (default, dev, tasks, full) | `default` |
| `--depth` | Maximum tree depth | Unlimited |
| `--autocorrect` | Enable path autocorrection | `true` |

**Examples**
```bash
nav-tree --context dev
nav-tree --depth 3 docs/
```
</details>

### `handbook` – Development handbook access   {#handbook--development-handbook-access}

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

### `release-manager` – Release management tool   {#release-manager--release-management-tool}

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

## Tool Categories   {#tool-categories}

### By Function   {#by-function}

* **Code Review**: `code-review`, `code-review-prepare`,
  `code-review-synthesize`
* **Git Operations**: `git-add`, `git-commit`, `git-diff`, `git-fetch`,
  `git-log`, `git-pull`, `git-push`, `git-status`
* **LLM Integration**: `llm-query`
* **Navigation & Documentation**: `handbook`, `nav-ls`, `nav-path`,
  `nav-tree`
* **Project Management**: `release-manager`, `task-manager`
* **Reflection & Analysis**: `reflection-synthesize`

### By Persona   {#by-persona}

* **AI Agent**: `llm-query`, `nav-path`, `release-manager`,
  `task-manager`
* **Human Developer**: `code-review`, `handbook`,
  `reflection-synthesize`
* **Git Power-User**: `git-add`, `git-commit`, `git-diff`, `git-status`
* **Release Manager**: `release-manager`, `task-manager`

## Common Workflows   {#common-workflows}

### AI Agent Workflow   {#ai-agent-workflow}

    # Find next task and navigate
    task-manager next
    nav-path task 42
    
    # Locate files intelligently (instead of find/ls)
    nav-path file config        # Find configuration files
    nav-path file blueprint     # Find docs/blueprint.md
    nav-path file README        # Find README files
    
    # Query AI for implementation guidance
    llm-query google "How to implement feature X?"
    
    # Generate new task when needed
    nav-path task-new --title "Implement feature X"
{: .language-bash}

### Human Developer Workflow   {#human-developer-workflow}

    # Sync documentation and review code
    handbook sync-templates
    code-review --interactive
    
    # Track recent work and generate reflection
    task-manager recent
    reflection-synthesize --session current
{: .language-bash}

### Git Power-User Workflow   {#git-power-user-workflow}

    # Enhanced git operations across repositories
    git-status --verbose
    git-diff --stat
    git-commit --intention "update features"
    git-push
{: .language-bash}

## Notes   {#notes}

* All tools available directly by name via fish integration
* Use `tool-name --help` for detailed usage information
* Git wrappers provide enhanced functionality over standard git commands
* LLM integration includes intelligent caching and cost tracking

* * *

*For the most up-to-date information, run individual tools with `--help`
flag.*

