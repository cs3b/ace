---
update:
  update_frequency: on-change
  auto_generate:
  - template-refs: from-embedded
  frequency: on-change
  last-updated: '2025-09-25'
---

# Code Review Workflow Instruction

## Goal

Perform comprehensive code review using the modernized `code-review` command with preset configurations and automated execution.

## Context Loading

**FIRST: Load the code review context for all reference information:**
```bash
context --preset code-review
```

This provides:
- Complete command help and options
- All 14 available presets with descriptions
- Available prompt modules (base, format, focus, guidelines)
- Tool documentation and examples

## ⚠️ CRITICAL: AI Agent Instructions ⚠️

**FOR AI CODING AGENTS - READ THIS FIRST**

### What TO DO:
1. **Run `context --preset code-review`** for reference
2. **Select appropriate preset** or compose custom configuration
3. **Execute code-review** with `--auto-execute` flag
4. **Review generated report** for insights

### What NOT TO DO:
- ❌ Use Read tool on individual source files (do not run git show and git diff directly - only run the code-review)
- ❌ Manually run llm-query (handled by --auto-execute)
- ❌ Create tasks (user's responsibility after reviewing reports)
- ❌ Skip the context loading step

## Prerequisites

- Access to `code-review` command (v2.0+)
- LLM provider configured (default: google:gemini-2.5-flash)

## Primary Workflow: Multi-Repository Review

### The Main Command Pattern

```bash
# Multi-repository review with all diffs
code-review \
  --preset ruby-atom-modular \
  --context 'presets: [project]' \
  --subject 'commands: [
    "git diff 8e7882c~1..HEAD",
    # Add more repository diffs as needed
  ]' \
  --add-focus 'scope/tests,scope/docs' \
  --model "google:gemini-2.5-flash" \
  --auto-execute
```

### Key Parameters Explained

- **`--preset`**: Base configuration (see `code-review --list-presets`)
- **`--context`**: Background docs to include (presets or files)
- **`--subject`**: What to review (commands for diffs, or file patterns)
- **`--add-focus`**: Additional focus modules to layer on preset
- **`--auto-execute`**: Run LLM query immediately (no manual steps)

## Quick Discovery Commands

```bash
# See what's available
code-review --list-presets   # All preset configurations
code-review --list-prompts   # All modular components
code-review --help           # Full command documentation
```

## Common Scenarios

### Daily PR Review
```bash
code-review --preset pr --auto-execute
```

### Pre-Commit Check
```bash
code-review --preset code \
  --subject 'commands: ["git diff --staged"]' \
  --auto-execute
```

### Architecture Compliance
```bash
code-review --preset ruby-atom-modular \
  --context 'presets: [project, dev-tools]' \
  --auto-execute
```

## Using Context Files

When review parameters are complex, store them in a context file:

```markdown
# .ace-taskflow/$(ace-taskflow release --path)/*/docs/code-review-contexts.md
subject: diff from sha till HEAD on following repos

[main]         8e7882c chore: update submodules
# [other-repo] commit-sha description

context:
- presets: project
- focus modules:
    - architecture/atom
    - languages/ruby
```

Then reference the parameters in your command.

## Essential Tips

### Troubleshooting

| Issue | Solution |
|-------|----------|
| "Preset not found" | Run `code-review --list-presets` |
| "Git diff empty" | Check git range with `git diff` |
| "LLM timeout" | Narrow the review scope |

### Debug Mode
```bash
# See what would be executed
code-review --preset pr --dry-run

# Check preset configuration
grep -A 10 "ruby-atom-modular:" .coding-agent/code-review.yml
```

## Success Criteria

- ✅ Context loaded with `context --preset code-review`
- ✅ Appropriate preset or configuration selected
- ✅ Subject correctly specified (diffs or files)
- ✅ Command executed with `--auto-execute`
- ✅ Review report generated and saved
- ✅ No manual llm-query execution needed

## Summary

1. **Load context**: `context --preset code-review` for reference
2. **Choose approach**: Preset, custom, or context file
3. **Execute**: Single command with `--auto-execute`
4. **Review**: Read generated report for insights

**Remember**: This workflow generates review reports only. Task creation is the user's responsibility after reviewing the reports.

---

*For complete reference, always run `context --preset code-review` first.*
