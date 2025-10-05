# Code Review Workflow Instruction

## Goal

Perform comprehensive code review using the `ace-review` command with preset configurations and automated execution.

## Context Loading

**FIRST: Load the code review context for all reference information:**
```bash
ace-review --list-presets
ace-review --list-prompts
```

This provides:
- Complete command help and options
- All 14 available presets with descriptions
- Available prompt modules (base, format, focus, guidelines)
- Tool documentation and examples

## ⚠️ CRITICAL: AI Agent Instructions ⚠️

**FOR AI CODING AGENTS - READ THIS FIRST**

### What TO DO:
1. **Run `ace-review --list-presets`** for reference
2. **Select appropriate preset** or compose custom configuration
3. **Execute `ace-review`** with `--auto-execute` flag
4. **Review generated report** for insights

### What NOT TO DO:
- ❌ Use Read tool on individual source files (do not run git show and git diff directly - only run ace-review)
- ❌ Manually run llm-query (handled by --auto-execute)
- ❌ Create tasks (user's responsibility after reviewing reports)
- ❌ Skip the context loading step

## Prerequisites

- Access to `ace-review` command
- LLM provider configured (default: google:gemini-2.5-flash)

## Primary Workflow: Multi-Repository Review

### The Main Command Pattern

```bash
# Multi-repository review with all diffs
ace-review \
  --preset ruby-atom \
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

- **`--preset`**: Base configuration (see `ace-review --list-presets`)
- **`--context`**: Background docs to include (presets or files)
- **`--subject`**: What to review (commands for diffs, or file patterns)
- **`--add-focus`**: Additional focus modules to layer on preset
- **`--auto-execute`**: Run LLM query immediately (no manual steps)

## Quick Discovery Commands

```bash
# See what's available
ace-review --list-presets   # All preset configurations
ace-review --list-prompts   # All modular components
ace-review --help           # Full command documentation
```

## Common Scenarios

### Daily PR Review
```bash
ace-review --preset pr --auto-execute
```

### Pre-Commit Check
```bash
ace-review --preset code \
  --subject 'commands: ["git diff --staged"]' \
  --auto-execute
```

### Architecture Compliance
```bash
ace-review --preset ruby-atom-modular \
  --context 'presets: [project, dev-tools]' \
  --auto-execute
```

## Using Context Files

When review parameters are complex, store them in a context file:

```markdown
# .ace-taskflow/$(ace-taskflow release --path)/*/docs/ace-review-contexts.md
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
| "Preset not found" | Run `ace-review --list-presets` |
| "Git diff empty" | Check git range with `git diff` |
| "LLM timeout" | Narrow the review scope |

### Debug Mode
```bash
# See what would be executed
ace-review --preset pr --dry-run

# Check preset configuration
grep -A 10 "ruby-atom-modular:" .coding-agent/ace-review.yml
```

## Success Criteria

- ✅ Context loaded with `context --preset ace-review`
- ✅ Appropriate preset or configuration selected
- ✅ Subject correctly specified (diffs or files)
- ✅ Command executed with `--auto-execute`
- ✅ Review report generated and saved
- ✅ No manual llm-query execution needed

## Summary

1. **Load context**: `context --preset ace-review` for reference
2. **Choose approach**: Preset, custom, or context file
3. **Execute**: Single command with `--auto-execute`
4. **Review**: Read generated report for insights

**Remember**: This workflow generates review reports only. Task creation is the user's responsibility after reviewing the reports.

---

*For complete reference, always run `context --preset ace-review` first.*
