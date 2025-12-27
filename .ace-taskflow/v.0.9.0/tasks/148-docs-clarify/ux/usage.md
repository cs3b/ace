# Command Types Documentation - Usage Guide

## Overview

ACE provides two types of commands for developers:

1. **Claude Commands** (`/ace:*`) - Slash commands run from within Claude Code conversations
2. **CLI Tools** (`ace-*`) - Terminal commands run from bash/fish shell

This guide shows how to identify and use each command type correctly.

## Command Type Distinction

### Claude Commands (Agent Slash Commands)

**What they are:** Slash commands that invoke workflows within Claude Code (or similar AI agent environments).

**How to identify:**
- Always prefixed with `/` (slash)
- Use colon separator: `/ace:command-name`
- Only work inside Claude Code conversations

**Example:**
```
/ace:commit [intention]
/ace:work-on-task 123
/ace:load-context project
```

**Where to run:** Type directly in Claude Code chat input

### CLI Tools (Terminal Commands)

**What they are:** Executable commands installed as Ruby gems that run in your terminal.

**How to identify:**
- Start with `ace-` prefix (no slash)
- Use hyphen separator: `ace-tool-name`
- Run in bash, fish, or any shell

**Example:**
```bash
ace-git-commit -i "fixing bug"
ace-taskflow task 123
ace-context project
```

**Where to run:** Terminal/shell (bash, fish, zsh, etc.)

## Usage Scenarios

### Scenario 1: Committing Code Changes

**Goal:** Create a well-structured git commit with a generated message

**Using Claude Command (from Claude Code conversation):**
```
/ace:commit fixing authentication bug
```
Claude will execute the workflow, review changes, and create the commit.

**Using CLI Tool (from terminal):**
```bash
ace-git-commit -i "fixing authentication bug"
```
Runs directly in terminal, generates commit message via LLM, creates commit.

### Scenario 2: Working on a Task

**Goal:** Start working on task #148

**Using Claude Command:**
```
/ace:work-on-task 148
```
Claude loads the task, follows the workflow, and implements step-by-step.

**Using CLI Tool (to find task info only):**
```bash
ace-taskflow task 148
```
Shows task details and path. Then use Claude command to work on it.

### Scenario 3: Loading Project Context

**Goal:** Load project context for understanding the codebase

**Using Claude Command:**
```
/ace:load-context project
```
Claude loads context and uses it to answer questions.

**Using CLI Tool:**
```bash
ace-context project
```
Outputs context to file; use `cat` or editor to read.

### Scenario 4: Code Review

**Goal:** Review changes in a pull request

**Using Claude Command:**
```
/ace:review-pr 97
```
Claude fetches PR, analyzes changes, provides structured review.

**Using CLI Tool:**
```bash
ace-review --preset pr --pr 97
```
Generates review report to file; open separately to read.

## Quick Reference Table

| Task | Claude Command | CLI Tool |
|------|----------------|----------|
| Commit changes | `/ace:commit [msg]` | `ace-git-commit -i "msg"` |
| Work on task | `/ace:work-on-task N` | `ace-taskflow task N` (info only) |
| Load context | `/ace:load-context preset` | `ace-context preset` |
| Review PR | `/ace:review-pr N` | `ace-review --pr N` |
| Draft task | `/ace:draft-task "title"` | `ace-taskflow task create "title"` |
| Run tests | `/ace:fix-tests` | `ace-test` |
| Create PR | `/ace:create-pr` | `gh pr create` |

## Key Differences

| Aspect | Claude Commands | CLI Tools |
|--------|-----------------|-----------|
| **Prefix** | `/ace:` (slash) | `ace-` (no slash) |
| **Environment** | Claude Code conversation | Terminal shell |
| **Execution** | AI-guided workflow | Direct command execution |
| **Output** | Integrated in conversation | Stdout/files |
| **Interactivity** | Claude follows up, asks questions | One-shot execution |

## Tips and Best Practices

### When to Use Claude Commands
- Complex multi-step workflows (task execution, code review)
- When you want Claude to guide the process
- When context-aware decisions are needed
- When you need conversational follow-up

### When to Use CLI Tools
- Quick lookups (task info, file searches)
- Scripting and automation
- Standalone operations without AI guidance
- When you need raw output for processing

### Common Pitfalls

1. **Trying Claude commands in terminal:**
   ```bash
   # WRONG - this won't work in terminal
   /ace:commit fixing bug

   # CORRECT - use CLI tool
   ace-git-commit -i "fixing bug"
   ```

2. **Using CLI syntax in Claude Code:**
   ```
   # Suboptimal in Claude - will work but misses workflow
   ace-taskflow task 123

   # Better - uses full workflow
   /ace:work-on-task 123
   ```

3. **Confusing similar names:**
   - `/ace:commit` = Claude command for commit workflow
   - `ace-git-commit` = CLI tool for commit execution

## Troubleshooting

### "Command not found" in terminal
You're trying to run a Claude command in terminal. Remove the `/` prefix and use the corresponding CLI tool:
- `/ace:commit` -> `ace-git-commit`
- `/ace:work-on-task` -> `ace-taskflow task`

### Claude doesn't recognize command
Ensure you're using the correct format:
- Use `/ace:command-name` (with slash and colon)
- Check the command exists in `.claude/commands/ace/`

### CLI tool returns unexpected output
Remember CLI tools write to stdout/files. Use appropriate tools to view:
```bash
ace-context project  # outputs to file
cat .cache/ace-context/project.md  # read the output
```

## Migration from Legacy Commands

If you're used to older command patterns:

| Old Pattern | New Claude Command | New CLI Tool |
|-------------|-------------------|--------------|
| `run ace:commit` | `/ace:commit` | `ace-git-commit` |
| `use commit workflow` | `/ace:commit` | `ace-git-commit` |
| Manual commit message | `/ace:commit` | `ace-git-commit` |
