# CLAUDE.md

Agent guidance for the Coding Agent Workflow Toolkit (Meta) repository.

## Command Types

This project has two distinct types of commands. Understanding the difference is essential:

### Claude Commands (Slash Commands)

**Run from:** Claude Code conversation (type directly in chat)
**Prefix:** `/ace-`
**Purpose:** Invoke AI-assisted workflows with full agent context

Examples:
- `/ace-task-work 148` - Work on a specific task with full context
- `/ace-git-commit` - Generate intelligent commit with LLM assistance
- `/ace-review-pr 90` - Review a pull request with AI analysis
- `/ace-task-draft` - Draft a new task specification


### Special Shortcut conventions

#### ">" use ace-bundle to load content

">project" -> read content from Bash(ace-bundle project)
">guide://markdown-style" -> load content from Bash(ace-bundle guide://markdown-style) 


#### ">>" read content from ace-bundle command and run instructions 

">>git/commit" -> read and run instructions from Bash(ace-bundle wfi://git/commit)

### CLI Tools (Terminal Commands)

**Run from:** Terminal (bash/fish shell)
**Prefix:** `ace-` (hyphenated)
**Purpose:** Deterministic operations for direct execution

Examples:
```bash
ace-task show 148  # Show task details
ace-git-commit --staged     # Generate commit message
ace-review --preset pr      # Run code review preset
ace-test atoms              # Run atom tests
```

### Quick Reference

| Type | Environment | Prefix | Example |
|------|-------------|--------|---------|
| Claude Command | Chat | `/ace-` | `/ace-task-work 121` |
| CLI Tool | Terminal | `ace-` | `ace-task show 121` |

## Command Recognition

Agents should recognize these command patterns:

- `@.claude/skills/ace/load-context.md` → Use ace-bundle
- `@.claude/skills/*` → Follow specific skill instructions

## Workflow Context Embedding

**Best practice**: When agents invoke workflows via `/ace-command`, the workflow may include embedded context (via `embed_document_source: true`).

Agents should:
1. Check for embedded XML sections like `<current_repository_status>` or `<available_presets>`
2. Use this context instead of running redundant commands
3. Reference embedded sections explicitly in responses

**Example**: When `/ace-git-commit` is invoked, the workflow includes `<current_repository_status>` with git state. No need to run `git status` separately.

For full patterns and guidance, run `ace-bundle guide://workflow-context-embedding`.

## CLI Tool Usage

The following are CLI tools that run in your terminal (bash/fish). See also: [docs/tools.md](docs/tools.md) for complete reference.

### ace-bundle (CLI Tool)

**Purpose**: Load project context from presets, files, or protocols
**Command**: `ace-bundle [input]`
**Examples**:

- `ace-bundle project` (default context)
- `ace-bundle wfi://bundle` (flat protocol)
- `ace-bundle wfi://task/work` (namespaced protocol)

### ace-nav (CLI Tool)

**Purpose**: Resource discovery with protocol support
**Command**: `ace-nav [protocol://resource]`
**Protocols**: wfi://, guide://, prompt://, tmpl://
**Examples**:

- `ace-bundle wfi://bundle` → Read output file path, then read that file
- `ace-nav --sources` → List available resource sources

### ace-* CLI Tools: Output Handling (Terminal)

**CRITICAL**: `ace-*` output handling is a hard contract, not a suggestion.

- **Required invocation**: run directly as `ace-*` (or `mise exec -- ace-*` where required by local repo rules)
- **Never use shell manipulation** on `ace-*` invocations:
  - pipes: `|`, `|&`
  - redirects: `>`, `>>`, `2>`, `&>`
  - post-processing: `head`, `tail`, `grep`, `awk`, `sed`, `tee`, `xargs`
  - command substitution/backgrounding: `$()`, backticks, trailing `&`
- **Allowed**: Using `Read` tool on file paths referenced in command output
- **Why**: ace-* tools produce concise output by design and provide file paths for detailed content
- **Pattern**: Run the command directly, then use `Read` tool on any referenced file paths

**Anti-pattern examples to AVOID**:
❌ `ace-review --pr 90 | tail -20`
❌ `tail -f /tmp/claude/.../output`
❌ `ace-bundle project | head -100`
❌ `ace-bundle project > /tmp/ace_bundle_project.txt`
❌ `ace-task list | grep done`

**Correct patterns**:
✅ `ace-review --pr 90` → then `Read` the synthesis report path from output
✅ `ace-bundle project` → output is already concise; read referenced files as needed
✅ `ace-bundle wfi://namespace/action` → returns workflow content (may include embedded context)
✅ `ace-task list` → consume native output directly (no shell filtering)

If this rule is violated, rerun the same `ace-*` command in compliant form immediately and treat that rerun as source of truth.

Never reset or discard changes you didn't make - use `ace-git-commit $paths` to commit only your changes.

## Testing Constraints

**CRITICAL**: NEVER use `bundle exec rake test` or `bundle exec ruby` for running tests in this project.

**ALWAYS use `ace-test`** instead:

### ace-test (CLI Tool)

Run from terminal:
- `ace-test` - Run all tests in current package
- `ace-test test/file_test.rb` - Run single test file
- `ace-test atoms` - Run test group
- `ace-test molecules --profile 10` - Profile slowest tests (optionally in a group)

**Why**: ace-test provides consistent test execution across the mono-repo with proper dependency resolution.

**Anti-pattern examples to AVOID**:
❌ `cd ace-review && bundle exec rake test`
❌ `bundle exec ruby test/some_test.rb`
✅ `cd ace-review && ace-test`
✅ `ace-test test/molecules/gh_pr_fetcher_test.rb`

### ace-test-suite (CLI Tool)

Validate entire monorepo (final check before commits).

- `ace-test-suite` - Run all tests across all packages

## Search & Research Commands

- `/ace-search-run` - Code/file search and discovery
- `/ace-search-research` - Multi-search analysis and synthesis
- `/ace-search-feature-research` - Feature gap analysis and implementation patterns

**Usage**: Invoke via `/ace-command` in Claude Code

## Project Context

For comprehensive project details, run: `ace-bundle project`
This provides architecture, tools, conventions, and structure (1371 lines).

**Key Point**: Do not duplicate project context in responses - reference ace-bundle output.

### Special Shortcut conventions (repeated)

#### ">" use ace-bundle to load content

">project" -> read content from Bash(ace-bundle project)
">guide://markdown-style" -> load content from Bash(ace-bundle guide://markdown-style) 


#### ">>" read content from ace-bundle command and run instructions 

">>git/commit" -> read and run instructions from Bash(ace-bundle wfi://git/commit)
