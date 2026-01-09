# Skills Usage Guide - Agent to Skill Conversion

## Overview

This document describes the usage patterns for converted agents, now available as skills (Claude Code slash commands). Skills are invoked with `/ace:command` syntax and delegate to workflow instructions.

## Available Skills (After Conversion)

| Skill Command | Description | Source Package |
|---------------|-------------|----------------|
| `/ace:search` | Search codebase patterns | ace-search |
| `/ace:research` | Multi-search codebase research | ace-search |
| `/ace:feature-research` | Feature gap analysis | ace-search |
| `/ace:security-audit` | Token leak detection | ace-git-secrets |
| `/ace:worktree` | Git worktree management | ace-git-worktree |
| `/ace:timestamp` | Timestamp encoding/decoding | ace-timestamp |
| `/ace:lint` | Code linting workflow | ace-lint |
| `/ace:release-navigator` | Release discovery | ace-taskflow |
| `/ace:task-finder` | Task discovery | ace-taskflow |
| `/ace:task-creator` | Task creation | ace-taskflow |
| `/ace:commit` | Git commit (existing) | ace-git-commit |

## Command Types

### Skill Commands (Claude Code Chat)

**Prefix:** `/ace:` (typed directly in Claude Code conversation)
**Purpose:** AI-assisted workflows with full agent context

```
# In Claude Code chat
/ace:search "class.*Manager"
/ace:research "How is authentication implemented?"
/ace:commit "Fix authentication bug"
```

### CLI Tools (Terminal)

**Prefix:** `ace-` (run in terminal/bash)
**Purpose:** Direct deterministic execution

```bash
# In terminal
ace-search "class.*Manager"
ace-taskflow tasks
ace-git-commit --staged
```

## Usage Scenarios

### Scenario 1: Code Search

**Goal:** Find all instances of a pattern in the codebase

**Skill Invocation:**
```
/ace:search "def.*process"
```

**Expected Output:**
- Summary of matches found
- File paths and line numbers
- Refinement suggestions

### Scenario 2: Codebase Research

**Goal:** Understand how a feature is implemented

**Skill Invocation:**
```
/ace:research "How is task management implemented?"
```

**Expected Output:**
- Search strategy used
- Key findings with file:line references
- Architecture summary
- Code examples
- Related components

### Scenario 3: Security Audit

**Goal:** Check for leaked tokens before release

**Skill Invocation:**
```
/ace:security-audit --scope full
```

**Expected Output:**
- Findings summary by confidence level
- Critical findings requiring immediate action
- Remediation recommendations

### Scenario 4: Task Discovery

**Goal:** Find next tasks to work on

**Skill Invocation:**
```
/ace:task-finder
```

**Expected Output:**
- List of pending tasks
- Priority and status information
- Suggested next actions

### Scenario 5: Worktree Management

**Goal:** Create worktree for a specific task

**Skill Invocation:**
```
/ace:worktree create --task 180
```

**Expected Output:**
- Worktree path
- Branch created
- Task status updated
- Next steps

### Scenario 6: Feature Gap Analysis

**Goal:** Identify missing features in a system area

**Skill Invocation:**
```
/ace:feature-research "authentication system"
```

**Expected Output:**
- Current state analysis
- Comparable systems research
- Prioritized feature list
- Implementation readiness assessment

## Command Reference

### /ace:search

Search codebase patterns using ace-search.

**Syntax:**
```
/ace:search [pattern] [options]
```

**Arguments:**
- `pattern` - Search pattern (text, regex, or file glob)

**Options:**
- `--file` - Search file names only
- `--content` - Search file contents only
- `--glob "pattern"` - Filter by file pattern

**Internal Implementation:**
Runs `ace-context wfi://search`, which invokes `ace-search` CLI.

### /ace:research

Multi-search codebase research with synthesis.

**Syntax:**
```
/ace:research [goal] [options]
```

**Arguments:**
- `goal` - Research objective

**Options:**
- `--depth shallow|normal|deep` - Research depth
- `--scope "path"` - Limit to specific path

**Internal Implementation:**
Runs `ace-context wfi://research`, which orchestrates multiple ace-search calls.

### /ace:security-audit

Detect leaked authentication tokens.

**Syntax:**
```
/ace:security-audit [options]
```

**Options:**
- `--scope full|recent|staged` - Audit scope
- `--confidence low|medium|high` - Minimum confidence

**Internal Implementation:**
Runs `ace-context wfi://security-audit`, which invokes `ace-git-secrets scan`.

### /ace:worktree

Manage git worktrees with task awareness.

**Syntax:**
```
/ace:worktree [action] [options]
```

**Actions:**
- `create` - Create new worktree
- `list` - List worktrees
- `switch` - Switch to worktree
- `remove` - Remove worktree

**Options:**
- `--task <id>` - Task ID for task-aware operations

**Internal Implementation:**
Runs `ace-context wfi://worktree`, which invokes `ace-git-worktree` CLI.

## Tips and Best Practices

### When to Use Skills vs CLI

**Use Skills (`/ace:`):**
- When you need AI interpretation of results
- For complex multi-step workflows
- When context and synthesis are important

**Use CLI (`ace-`):**
- For quick, direct operations
- In scripts and automation
- When you need raw output

### Common Pitfalls to Avoid

1. **Don't mix prefixes** - Use `/ace:` for skills, `ace-` for CLI
2. **Don't use @agent** - Agents are deprecated, use `/ace:` skills
3. **Check skill list** - Run `/ace:` to see available skills

### Performance Considerations

- Skills load workflow instructions via `ace-context`
- First invocation may be slower (cache building)
- Subsequent invocations are faster

### Troubleshooting

**Skill not found:**
- Verify skill command file exists in `.claude/commands/ace/`
- Check file has valid frontmatter with `description`

**Workflow load failed:**
- Run `ace-context wfi://workflow-name` manually to check
- Verify workflow instruction file exists

## Migration Notes

### Legacy vs New

| Legacy (Deprecated) | New (Preferred) |
|---------------------|-----------------|
| `@search` | `/ace:search` |
| `@research` | `/ace:research` |
| Agent symlinks in `.claude/agents/` | Skills in `.claude/commands/ace/` |

### Key Differences

1. **Invocation:** `@agent` -> `/ace:command`
2. **Location:** `.claude/agents/*.ag.md` -> `.claude/commands/ace/*.md`
3. **Pattern:** Inline instructions -> Workflow delegation
4. **Discovery:** Manual -> Claude Code skill completion

### Transition Guidance

During transition:
1. Both `@agent` and `/ace:` may work
2. Prefer `/ace:` for new usage
3. Update documentation to reference skills
4. Agent files remain but are deprecated
