# CLAUDE.md

Agent guidance for the Coding Agent Workflow Toolkit (Meta) repository.

## Command Types

This project has two distinct types of commands. Understanding the difference is essential:

### Claude Commands (Slash Commands)

**Run from:** Claude Code conversation (type directly in chat)
**Prefix:** `/ace:` or `/meta-`
**Purpose:** Invoke AI-assisted workflows with full agent context

Examples:
- `/ace:work-on-task 148` - Work on a specific task with full context
- `/ace:commit` - Generate intelligent commit with LLM assistance
- `/ace:review-pr 90` - Review a pull request with AI analysis
- `/ace:draft-task` - Draft a new task specification

### CLI Tools (Terminal Commands)

**Run from:** Terminal (bash/fish shell)
**Prefix:** `ace-` (hyphenated)
**Purpose:** Deterministic operations for direct execution

Examples:
```bash
ace-taskflow task 148       # Show task details
ace-git-commit --staged     # Generate commit message
ace-review --preset pr      # Run code review preset
ace-test atoms              # Run atom tests
```

### Quick Reference

| Type | Environment | Prefix | Example |
|------|-------------|--------|---------|
| Claude Command | Chat | `/ace:` | `/ace:work-on-task 121` |
| CLI Tool | Terminal | `ace-` | `ace-taskflow task 121` |

## Command Recognition

Agents should recognize these command patterns:

- `@.claude/commands/ace/load-context.md` → Use ace-context
- `@.claude/commands/*` → Follow specific command instructions

## CLI Tool Usage

The following are CLI tools that run in your terminal (bash/fish). See also: [docs/tools.md](docs/tools.md) for complete reference.

### ace-context (CLI Tool)

**Purpose**: Load project context from presets, files, or protocols
**Command**: `ace-context [input]`
**Examples**:

- `ace-context project` (default context)
- `ace-context wfi://load-context` (protocol)

### ace-nav (CLI Tool)

**Purpose**: Resource discovery with protocol support
**Command**: `ace-nav [protocol://resource]`
**Protocols**: wfi://, guide://, prompt://, tmpl://
**Examples**:

- `ace-nav wfi://load-context` → Read output file path, then read that file
- `ace-nav --sources` → List available resource sources

### ace-* CLI Tools: Output Handling (Terminal)

**IMPORTANT**: Do NOT use shell output manipulation with ace-* tools:

- **Avoid**: `tail -f`, `head`, `grep`, pipes on long output, redirects
- **Allowed**: Using `Read` tool on file paths referenced in command output
- **Why**: ace-* tools produce concise output by design and provide file paths for detailed content
- **Pattern**: Run the command directly, then use `Read` tool on any referenced file paths

**Anti-pattern examples to AVOID**:
❌ `ace-review --pr 90 | tail -20`
❌ `tail -f /tmp/claude/.../output`
❌ `ace-context project | head -100`

**Correct patterns**:
✅ `ace-review --pr 90` → then `Read` the synthesis report path from output
✅ `ace-context project` → output is already concise; read referenced files as needed
✅ `ace-nav wfi://workflow` → returns file path, then `Read` that file

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

## Available Agents

**Location**: `.claude/agents/` (symlinks to ace-search/handbook/agents/)

- **@search**: Code/file search and discovery
- **@research**: Multi-search analysis and synthesis

**Usage**: Direct invocation (`@agent`) or Task tool (`subagent_type: agent-name`)

## Project Context

For comprehensive project details, run: `ace-context project`
This provides architecture, tools, conventions, and structure (1371 lines).

**Key Point**: Do not duplicate project context in responses - reference ace-context output.
