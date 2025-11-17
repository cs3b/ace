# CLAUDE.md

Agent guidance for the Coding Agent Workflow Toolkit (Meta) repository.

## Command Recognition

Agents should recognize these command patterns:

- `@.claude/commands/ace/load-context.md` → Use ace-context
- `@.claude/commands/*` → Follow specific command instructions
- `@search` → Use search agent from `.claude/agents/`
- `@research` → Use research agent from `.claude/agents/`

## Tool Usage

### ace-context: Load Context

**Purpose**: Load project context from presets, files, or protocols
**Command**: `ace-context [input]`
**Examples**:

- `ace-context project` (default context)
- `ace-context wfi://load-context` (protocol)

### ace-nav: Navigate Resources

**Purpose**: Resource discovery with protocol support
**Command**: `ace-nav [protocol://resource]`
**Protocols**: wfi://, guide://, prompt://, tmpl://
**Examples**:

- `ace-nav wfi://load-context` → Read output file path, then read that file
- `ace-nav --sources` → List available resource sources

## Testing Constraints

**CRITICAL**: NEVER use `bundle exec rake test` or `bundle exec ruby` for running tests in this project.

**ALWAYS use `ace-test`** instead:

### ace-test

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

### **ace-test-suite**: Validate entire monorepo (final check before commits)

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
