# Coding Agent Tools - Development Tools Reference   {#coding-agent-tools---development-tools-reference}

## Main Cheat-sheet   {#main-cheat-sheet}

| Tool | Purpose | Key Flags |
|----------
| **`search`** | **Unified intelligent search across project** | **`--type`, `--preset`** |
| `coding-agent-tools all` | List all available tools | `--format`, `--category` |
| `code-review` | Preset-based code review with context integration | `--preset`, `--context`, `--subject` |
| `code-review-synthesize` | Review synthesis tool | `--format`, `--include-recommendations` |
| `create-path` | Create files/directories with templates | `--force`, `--priority`, `--content` |
| `git-add` | Enhanced git add | `--patch`, `--all` |
| `git-commit` | Enhanced git commit | `--intention`, `--no-edit` |
| `git-diff` | Enhanced git diff | `--staged`, `--stat` |
| `git-fetch` | Enhanced git fetch | `--all`, `--prune` |
| `git-log` | Enhanced git log | `--oneline`, `--graph` |
| `git-pull` | Enhanced git pull | `--rebase`, `--ff-only` |
| `git-push` | Enhanced git push | `--force`, `--dry-run` |
| `git-status` | Enhanced git status | `--verbose`, `--short` |
| `git-tag` | Enhanced git tag | `[tagname]`, `--annotate`, `--delete`, `--list` |
| `handbook` | Development handbook access | `sync-templates`, `claude` subcommands |
| `llm-query` | Unified LLM query interface | `--model`, `--output` |
| `nav-ls` | Enhanced directory listing | `--long`, `--all` |
| `nav-path` | Intelligent path navigation | `task`, `file` |
| `nav-tree` | Enhanced project tree | `--context`, `--depth` |
| `reflection-synthesize` | Reflection report generator | `--session`, `--focus` |
| `release-manager` | Release management tool | `current`, `report` |
| `task-manager` | Project task management | `--filter`, `--sort`, `--limit` |

**🔍 Pro Tip**: Use `search` for all your searching needs! It intelligently determines whether you're looking for files or content, searches across the entire project, and supports interactive selection with `--fzf`. Examples:
- `search "TODO"` - Find all TODO comments
- `search "*.rb" --files` - Find Ruby files
- `search "def.*initialize" --type content` - Find initialize methods
- `search --preset todo` - Use built-in TODO preset
- `search "pattern" --fzf` - Interactive result selection

**💡 Pro Tip**: For file location, always use `nav-path file <filename>` instead of `find` or `ls` commands. It's intelligent, fast, and works with partial names (e.g., `nav-path file blueprint` finds `docs/blueprint.md`).

## Persona Cheat-sheets   {#persona-cheat-sheets}

### AI Agent   {#ai-agent}

| Tool | Purpose | Key Flags |
|------|---------|-----------|
| `task-manager` | Manage tasks | `create`, `--filter`, `--sort`, `--limit` |
| `llm-query` | Query AI models | `--model`, `--output` |
| `nav-path` | Navigate project paths | `task`, `file` |
| `release-manager` | Manage releases | `current`, `report` |

### Human Developer   {#human-developer}

| Tool | Purpose | Key Flags |
|------|---------|-----------|
| `code-review` | Review code with presets | `--preset`, `--model` |
| `handbook` | Access development guides | `sync-templates` |
| `reflection-synthesize` | Generate session reports | `--session`, `--focus` |

### Git Power-User   {#git-power-user}

| Tool | Purpose | Key Flags |
|------|---------|-----------|
| `git-add` | Enhanced file staging | `--patch`, `--all` |
| `git-commit` | Smart commit tool | `--intention`, `--no-edit` |
| `git-diff` | Advanced diff viewer | `--staged`, `--stat` |
| `git-status` | Multi-repo status | `--verbose`, `--short` |
| `git-tag` | Multi-repo tagging | `[tagname]`, `--annotate`, `--delete`, `--list` |

### Release Manager   {#release-manager}

| Tool | Purpose | Key Flags |
|------|---------|-----------|
| `release-manager` | Release coordination | `current`, `report` |
| `task-manager` | Track deliverables | `--filter`, `--sort`, `--limit` |

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

### `search` – Unified intelligent search across project   {#search--unified-intelligent-search-across-project}

<details><summary>Details</summary>

```bash
search [OPTIONS] PATTERN
```

| Flag | Purpose | Default |
|------|---------|---------|
| `-t, --type TYPE` | Search type (file, content, hybrid, auto) | `auto` |
| `-f, --files` | Search for files only | `false` |
| `-c, --content` | Search in file content only | `false` |
| `-i, --case-insensitive` | Case insensitive search | `false` |
| `-w, --whole-word` | Match whole words only | `false` |
| `-U, --multiline` | Enable multiline matching | `false` |
| `-A, --after NUM` | Show NUM lines after match | `0` |
| `-B, --before NUM` | Show NUM lines before match | `0` |
| `-C, --context NUM` | Show NUM lines of context | `0` |
| `-g, --glob PATTERN` | File glob pattern to include | None |
| `-e, --exclude PATTERN` | Pattern to exclude | None |
| `--since TIME` | Files modified since TIME | None |
| `--before TIME` | Files modified before TIME | None |
| `--staged` | Search staged files only | `false` |
| `--tracked` | Search tracked files only | `false` |
| `--changed` | Search changed files only | `false` |
| `--json` | Output in JSON format | `false` |
| `--yaml` | Output in YAML format | `false` |
| `-l, --files-with-matches` | Only print filenames | `false` |
| `--max-results NUM` | Limit number of results | None |
| `--fzf` | Use fzf for interactive selection | `false` |
| `-p, --preset NAME` | Use search preset | None |
| `--list-presets` | List available presets | N/A |

**Examples**
```bash
# Basic content search
search "TODO"

# Find all Ruby files
search "*.rb" --files

# Search with regex in content
search "def\s+initialize" --content

# Interactive selection with fzf
search "pattern" --fzf

# Use built-in preset
search --preset todo

# Search with path filtering
search "bug" --include "**/*.rb"

# Find recently modified files
search "*.md" --since "1 week ago"

# Case-insensitive whole word search
search "error" -i -w

# Search staged files only
search "console.log" --staged

# Output results as JSON
search "API" --json --max-results 10
```

**Built-in Presets**
- `todo` - Find TODO, FIXME, HACK, XXX, NOTE comments
- `ruby` - Find all Ruby files (*.rb)
- `tests` - Find all test files (*_spec.rb)
- `recent` - Find files modified in the last week
- `git-changes` - Find changed files in git

**Purpose:**
The search tool provides unified, intelligent searching across your entire project. It uses DWIM (Do What I Mean) heuristics to automatically determine whether you're searching for files or content, leverages ripgrep and fd for blazing-fast performance, and supports interactive result selection with fzf. Perfect for single-project workflows with streamlined, path-based results.

**Features:**
- Automatic mode detection (file vs content search)
- Streamlined, path-based output for single-project workflows
- Git-aware scopes (staged, tracked, changed files)
- Time-based file filtering
- Interactive result selection with fzf
- Configurable search presets
- Multiple output formats (text, JSON, YAML)
- Intelligent pattern analysis for optimal tool selection
- Simplified architecture focused on speed and usability

**Performance:**
- Uses ripgrep for content search (extremely fast)
- Uses fd for file search (faster than find)
- Streams results for immediate feedback
- Optimized for large codebases
</details>

## Glob Pattern Guide   {#glob-pattern-guide}

The `search` tool's `--glob` flag uses glob patterns for file filtering. Understanding these patterns is crucial for effective searching and avoiding common confusion.

### Basic Pattern Syntax

| Pattern | Meaning | Example |
|---------|---------|---------|
| `*` | Matches any characters except path separators | `*.rb` matches `file.rb`, `test.rb` |
| `**` | Matches any characters including path separators (recursive) | `**/*.rb` matches `lib/file.rb`, `spec/test/file.rb` |
| `?` | Matches exactly one character | `file?.rb` matches `file1.rb`, `filea.rb` |
| `[abc]` | Matches any character inside brackets | `file[123].rb` matches `file1.rb`, `file2.rb` |
| `{a,b}` | Matches any of the comma-separated alternatives | `*.{rb,py}` matches `file.rb`, `script.py` |

### Directory vs File Matching Behavior

**Critical difference between `**` and `**/*` patterns:**

```bash
# Matches both directories AND files at any depth under spec/
search --glob "spec/**" --files

# Matches ONLY files (not directories) at any depth under spec/  
search --glob "spec/**/*" --files

# Matches files directly in spec/ directory (one level only)
search --glob "spec/*" --files

# Matches only directories with trailing slash
search --glob "spec/*/" --files
```

This distinction is the most common source of confusion when using glob patterns.

### Common Use Cases and Recommended Patterns

#### Language-Specific File Searches
```bash
# Find all Ruby files
search --glob "**/*.rb" --files

# Find all JavaScript/TypeScript files  
search --glob "**/*.{js,ts,jsx,tsx}" --files

# Find all configuration files
search --glob "**/*.{yml,yaml,json,toml}" --files
```

#### Directory-Specific Searches
```bash
# Find files only in src directory and subdirectories
search --glob "src/**/*" --files

# Find test files in any test directory
search --glob "**/test/**/*.rb" --files
search --glob "**/spec/**/*_spec.rb" --files

# Find documentation files
search --glob "**/{docs,doc}/**/*.md" --files
```

#### Mixed Pattern Examples
```bash
# Find Ruby files but exclude test files
search --glob "**/*.rb" --exclude "**/test/**" --files

# Find recent configuration changes
search --glob "**/*.{yml,json}" --since "1 week ago" --files

# Find files with specific naming patterns
search --glob "**/*{_test,_spec,.test,.spec}.{rb,py,js}" --files
```

### Troubleshooting Common Pattern Issues

#### Problem: Pattern not matching expected files

**Issue**: `search --glob "spec/**" --files` returns directories, not files  
**Solution**: Use `spec/**/*` to match files only

**Issue**: Pattern seems correct but no results  
**Solutions**:
- Check if files actually exist: `search --glob "**/*" --files | head`
- Verify case sensitivity: add `--case-insensitive` flag
- Test simpler pattern first: `search --glob "*" --files`

#### Problem: Too many or too few results  

**Issue**: `search --glob "**/*"` returns thousands of files  
**Solutions**:
- Add file extension filter: `**/*.rb`
- Exclude large directories: `--exclude "node_modules/**"`
- Limit to specific directories: `src/**/*`

**Issue**: Pattern matches more than intended  
**Solutions**:
- Use more specific extensions: `**/*.spec.rb` instead of `**/*spec*`  
- Add exclusion patterns: `--exclude "vendor/**"`
- Combine with content search to filter further

### Pattern Performance Considerations

**Fast patterns** (use these when possible):
- `*.rb` - Single directory, specific extension
- `src/**/*.rb` - Specific root directory with extension
- `**/*.{rb,py}` - Specific extensions only

**Slower patterns** (use sparingly):
- `**/*` - Matches everything recursively
- `**/test*/**/*` - Complex nested matching
- `**/{a,b,c}/**/*` - Multiple alternative directories

**Performance Tips:**
1. **Be specific**: Use file extensions when you know them
2. **Limit scope**: Start with specific directories (`src/`, `lib/`)
3. **Use exclusions**: Filter out large directories like `node_modules/`
4. **Combine patterns**: Use `{ext1,ext2}` instead of multiple searches

### Advanced Pattern Examples

```bash
# Find all hidden config files
search --glob "**/.*" --files

# Find files modified today with specific extensions
search --glob "**/*.{rb,py,js}" --since "today" --files

# Find test files with complex naming patterns  
search --glob "**/*{_test,_spec,.test,.spec}.{rb,py,js}" --files

# Find documentation but exclude generated docs
search --glob "**/doc/**/*.md" --exclude "**/doc/generated/**" --files

# Find configuration files in standard locations
search --glob "**/{config,conf,settings}/**/*.{yml,yaml,json}" --files
```

### `coding_agent_tools all` – List all available tools   {#coding_agent_tools_all--list-all-available-tools}

<details><summary>Details</summary>

```bash
coding_agent_tools all [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `--format` | Output format (table, json, plain, names) | `table` |
| `--category` | Show tools from specific category only | All categories |
| `--no-descriptions` | Hide tool descriptions (faster output) | `false` |
| `--no-categories` | Don't group tools by category | `false` |

**Examples**
```bash
coding_agent_tools all
coding_agent_tools all --format json
coding_agent_tools all --category "Git Operations"
coding_agent_tools all --format names
coding_agent_tools all --no-descriptions
```
</details>

### `create-path` – Create files and directories with metadata and templates   {#create-path--create-files-and-directories-with-metadata-and-templates}

<details><summary>Details</summary>

```bash
create-path TYPE TARGET [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `--title` | Title for new path generation | Target argument |
| `--force`, `-f` | Force overwrite existing files | `false` |
| `--content` | Direct content for file creation | None |
| `--template` | Custom template path | Auto-detected |
| `--priority` | Priority level (high, medium, low) | `medium` |
| `--estimate` | Time estimate (e.g., '4h', '2d') | None |
| `--dependencies` | Comma-separated dependencies | None |
| `--status` | Initial status (pending, in-progress, done, blocked) | `pending` |

**Types:**
- `file` - Create file with direct content
- `directory` - Create directory with recursive support
- `docs-new` - Create documentation file
- `template` - Create file using custom template

**Examples**
```bash
# Create new task
task-manager create --title "implement-feature-x" --priority high --estimate 4h

# Create files and directories
create-path file README.md --content "# My Project"
create-path directory src/components
create-path docs-new "api-documentation" --title "API Documentation"
create-path template my-doc.md --template custom.template.md --title "Custom Doc"
```

**Configuration:**
Uses `.coding-agent/create-path.yml` for template mappings and variable definitions.
Delegates path resolution to PathResolver for consistent nav-path integration.
</details>

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

| Command | Purpose | Key Options |
|---------|---------|-------------|
| `next` | Show next actionable task | `--filter`, `--sort`, `--limit` |
| `list` | List all tasks | `--filter`, `--sort` |
| `all` | List all tasks (alias for list) | `--filter`, `--sort` |
| `recent` | Show recently modified tasks | `--limit`, `--last` |
| `generate-id` | Generate new task ID | N/A |

| Flag | Purpose | Example |
|------|---------|---------|
| `--filter` | Filter by status/priority | `status:pending`, `priority:high` |
| `--sort` | Sort criteria | `priority:desc,id:asc` |
| `--limit` | Maximum results | `3` |
| `--last` | Time period (recent only) | `2.days`, `1.week` |

**Examples**
```bash
task-manager next
task-manager list --filter status:draft
task-manager next --filter priority:high --limit 3
task-manager recent --last 2.days --limit 5
task-manager list --sort priority:desc,id:asc
```
</details>

### `code-review` – Preset-based code review with context integration   {#code-review--preset-based-code-review}

<details><summary>Details</summary>

```bash
code-review [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `--preset` | Review preset from code-review.yml | None |
| `--context` | Background information (docs, architecture) | None |
| `--subject` | What to review (diffs, files, commits) | None |
| `--system-prompt` | System prompt file path | None |
| `--model` | LLM model to use | `google:gemini-2.0-flash-exp` |
| `--output` | Output file for review report | stdout |
| `--list-presets` | List available review presets | `false` |
| `--dry-run` | Show what would be done | `false` |

**Examples**
```bash
# Use a preset for PR review
code-review --preset pr --model google:gemini-2.0-flash-exp

# Custom review with specific context and subject
code-review --context project --subject 'commands: ["git diff HEAD~1"]'

# Review with custom system prompt
code-review --context 'files: [docs/api.md]' --subject 'files: [lib/api/**/*.rb]' --system-prompt templates/api-review.md

# List available presets
code-review --list-presets
```

**Configuration**

Create `.coding-agent/code-review.yml` to define custom presets:

```yaml
presets:
  pr:
    description: "Pull request review"
    prompt_composition:
      base: "system"
      format: "standard"
      guidelines: ["tone", "icons"]
    context: "project"  # Background: project docs
    subject:            # What to review: PR changes
      commands:
        - git diff origin/main...HEAD
        - git log origin/main..HEAD --oneline
  
  code:
    description: "Code quality review"
    prompt_composition:
      base: "system"
      format: "standard"
      guidelines: ["tone", "icons"]
    context:
      files:
        - docs/architecture.md
        - CONTRIBUTING.md
    subject:
      commands:
        - git diff --cached

  ruby-atom:
    description: "Ruby ATOM architecture review"
    prompt_composition:
      base: "system"
      format: "standard"
      focus:
        - "architecture/atom"
        - "languages/ruby"
      guidelines: ["tone", "icons"]
    context: "project"
    subject:
      commands:
        - git diff HEAD~1..HEAD

defaults:
  model: "google:gemini-2.0-flash-exp"
  context: "project"
```

**Context vs Subject**
- **Context**: Background information (project docs, architecture) that informs the review
- **Subject**: The actual content to review (diffs, files, commits)
- The context enhances the system prompt with project knowledge
- The subject is what the LLM analyzes and reviews

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

### `git-tag` – Enhanced git tag   {#git-tag--enhanced-git-tag}

<details><summary>Details</summary>

```bash
git-tag [TAGNAME] [COMMIT] [OPTIONS]
```

**Arguments**

| Argument | Purpose |
|----------|---------|
| `TAGNAME` | The name of the tag to create, delete, or describe |
| `COMMIT` | The object that the new tag will refer to (defaults to HEAD) |

**Options**

| Flag | Purpose | Default |
|------|---------|---------|
| `--annotate`, `-a` | Make an unsigned, annotated tag object | `false` |
| `--sign`, `-s` | Make a GPG-signed tag | `false` |
| `--message`, `-m` | Use the given tag message | None |
| `--force`, `-f` | Replace an existing tag | `false` |
| `--delete`, `-d` | Delete existing tags | `false` |
| `--list`, `-l` | List tags | `false` |
| `--repository` | Specify repository context | All repos |
| `--main-only` | Process main repository only | `false` |
| `--submodules-only` | Process submodules only | `false` |

**Examples**
```bash
# List all tags across repositories
git-tag -l

# Create lightweight tag on HEAD
git-tag v1.2.3

# Create annotated tag with message
git-tag -a v1.2.3 -m "Release version 1.2.3"

# Create tag on specific commit
git-tag v1.2.3 abc123

# Delete tag across all repositories
git-tag -d v1.2.3

# Force replace existing tag
git-tag -f v1.2.3
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
| `task` | Resolve task by ID | N/A |
| `file` | Resolve file path | N/A |
| `--title` | Title for new items | Required |

**Examples**
```bash
# Task management
task-manager create --title "Feature Name"
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

| Command | Purpose |
|---------|---------|
| `sync-templates` | Sync template content |
| `claude` | Claude Code integration commands |

**Examples**
```bash
handbook sync-templates
handbook --help  # Shows all commands including claude-* commands
```
</details>

### `handbook claude` – Claude Code integration commands   {#handbook-claude--claude-code-integration-commands}

<details><summary>Details</summary>

```bash
handbook claude [SUBCOMMAND] [OPTIONS]
```

| Subcommand | Purpose | Key Options |
|---------|---------|-------------|
| `list` | List all Claude commands and their status | `--verbose`, `--type` |
| `validate` | Validate command coverage and consistency | `--strict`, `--fix` |
| `generate-commands` | Generate missing commands from workflows | `--dry-run`, `--force` |
| `integrate` | Run complete integration workflow | `--force`, `--skip-validation` |

**Common Options:**

| Flag | Purpose | Default |
|------|---------|---------|
| `--verbose` | Show detailed output | `false` |
| `--dry-run` | Preview changes without modifying files | `false` |
| `--force` | Force operation (overwrite/reinstall) | `false` |

**Examples**
```bash
# List all available commands
handbook claude list
handbook claude list --verbose
handbook claude list --type agent

# Validate command coverage
handbook claude validate
handbook claude validate --strict
handbook claude validate --fix

# Generate missing commands
handbook claude generate-commands
handbook claude generate-commands --dry-run
handbook claude generate-commands --force

# Run complete integration
handbook claude integrate
handbook claude integrate --force
handbook claude integrate --skip-validation
```

**Purpose:**
The Claude namespace provides tools for integrating with Claude Code (claude.ai/code). It manages the installation and maintenance of command files that enable Claude to understand and execute project-specific workflows.

**Features:**
- Automatic command generation from workflow instructions
- Smart categorization of custom vs generated commands
- Coverage validation to ensure all workflows have commands
- Registry management for tracking commands and agents
- Dry-run support for safe testing of changes
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

* **Code Review**: `code-review`, `code-review-synthesize`
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
    task-manager create --title "Implement feature X"
{: .language-bash}

### Human Developer Workflow   {#human-developer-workflow}

    # Sync documentation and review code
    handbook sync-templates
    code-review --preset pr --model google:gemini-2.0-flash-exp

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
