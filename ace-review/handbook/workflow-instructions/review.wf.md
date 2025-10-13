---
update:
  update_frequency: on-change
  auto_generate:
  - template-refs: from-embedded
  frequency: on-change
  last-updated: '2025-10-07'
---

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
- All available presets with descriptions
- Available prompt modules (base, format, focus, guidelines)
- Tool documentation and examples

**Note**: Since v0.9.6, ace-review uses ace-context for unified content aggregation, supporting `files:`, `diffs:`, `commands:`, and `presets:` in configuration.

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
# Multi-repository review with git diffs
ace-review \
  --preset ruby-atom \
  --context 'presets: [project]' \
  --subject 'diffs: ["8e7882c~1..HEAD", "origin/main...HEAD"]' \
  --add-focus 'scope/tests,scope/docs' \
  --model "google:gemini-2.5-flash" \
  --auto-execute

# Review specific files with context
ace-review \
  --preset code \
  --subject 'files: ["lib/ace/review/**/*.rb"]' \
  --context 'presets: [project]' \
  --auto-execute
```

### Key Parameters Explained

- **`--preset`**: Base configuration (see `ace-review --list-presets`)
- **`--context`**: Background docs to include (YAML config or preset name)
- **`--subject`**: What to review (YAML config, git range, keyword, or file pattern)
- **`--add-focus`**: Additional focus modules to layer on preset
- **`--auto-execute`**: Run LLM query immediately (no manual steps)

### Configuration Schema (ace-context v0.9.6+)

Both `--subject` and `--context` accept unified YAML configuration:

```yaml
# ✅ CORRECT: Use these keys
files: ["lib/**/*.rb", "docs/*.md"]      # File paths and glob patterns
diffs: ["origin/main...HEAD", "HEAD~5..HEAD"]  # Git diff ranges
commands: ["git log --oneline -5"]       # Shell commands to execute
presets: [project, architecture]         # ace-context preset names

# ❌ WRONG: Don't use 'patterns:' (removed in v0.9.6)
patterns: ["lib/**/*.rb"]  # No longer supported
```

**Simple String Shortcuts** (for `--subject`):
- `"staged"` → staged changes
- `"working"` → unstaged changes
- `"pr"` → changes vs tracking branch
- `"HEAD~1..HEAD"` → git range (auto-detected)
- `"lib/**/*.rb"` → file pattern (auto-detected)

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
# Simple: uses default subject (staged + working changes)
ace-review --preset pr --auto-execute

# Explicit: review changes vs main branch
ace-review --preset pr --subject 'diffs: ["origin/main...HEAD"]' --auto-execute
```

### Pre-Commit Check
```bash
# Review staged changes
ace-review --preset code --subject staged --auto-execute

# Or explicitly
ace-review --preset code --subject 'diffs: ["staged"]' --auto-execute
```

### Review Specific Files
```bash
# Review files matching pattern
ace-review --preset code \
  --subject 'files: ["lib/ace/review/**/*.rb"]' \
  --auto-execute

# Multiple file patterns
ace-review --preset code \
  --subject 'files: ["lib/**/*.rb", "spec/**/*_spec.rb"]' \
  --auto-execute
```

### Architecture Compliance
```bash
# Review with architectural context
ace-review --preset ruby-atom \
  --context 'presets: [project]' \
  --auto-execute
```

### Compose Multiple Sources
```bash
# Review files + diffs with full context
ace-review --preset code \
  --subject 'files: ["new-feature/**/*.rb"], diffs: ["HEAD~5..HEAD"]' \
  --context 'presets: [project], files: ["docs/architecture.md"]' \
  --auto-execute
```

## Using Context Files

When review parameters are complex, store them in a preset file:

```yaml
# .ace/review/presets/multi-repo.yml
description: "Review changes across main repo and submodules"

subject:
  diffs:
    - "8e7882c~1..HEAD"                    # Main repo: specific commit range
    - "origin/main...HEAD"                 # All changes vs main
  files:
    - "docs/CHANGELOG.md"                  # Include changelog

context:
  presets: [project]                       # Load project documentation
  files: ["docs/architecture.md"]          # Specific architectural docs

prompt:
  focus:
    - architecture/atom
    - languages/ruby
```

Then use the preset:
```bash
ace-review --preset multi-repo --auto-execute
```

## Essential Tips

### Troubleshooting

| Issue | Solution |
|-------|----------|
| "No code to review" | Use `files:` not `patterns:` → `--subject 'files: ["lib/**/*.rb"]'` |
| "Preset not found" | Run `ace-review --list-presets` to see available presets |
| "Git diff empty" | Check git range: `git log origin/main...HEAD` |
| "LLM timeout" | Narrow the review scope or use faster model |
| "Invalid git range" | Verify range exists: `git diff HEAD~5..HEAD` |

### Debug Mode
```bash
# See what would be executed
ace-review --preset pr --dry-run

# Verify subject extraction
ace-review --subject 'files: ["lib/**/*.rb"]' --dry-run --verbose

# Check preset configuration
ace-review --list-presets
cat .ace/review/presets/ruby-atom.yml
```

## Success Criteria

- ✅ Available presets and prompts listed
- ✅ Appropriate preset or configuration selected
- ✅ Subject correctly specified using `files:`, `diffs:`, or keywords
- ✅ Context properly configured (optional but recommended)
- ✅ Command executed with `--auto-execute`
- ✅ Review report generated and saved to session directory
- ✅ No manual llm-query execution needed

## Summary

1. **Discovery**: Run `ace-review --list-presets` and `--list-prompts`
2. **Configure**: Choose preset and specify subject/context
   - Use `files:` for file patterns
   - Use `diffs:` for git ranges
   - Use `presets:` for ace-context presets
   - Compose multiple sources as needed
3. **Execute**: Single command with `--auto-execute`
4. **Review**: Read generated report for insights

**Remember**:
- This workflow generates review reports only
- Use `files:` not `patterns:` for file patterns (v0.9.6+)
- All content extraction delegated to ace-context for unified aggregation
- Task creation is the user's responsibility after reviewing reports

---

*For complete reference, always run `context --preset ace-review` first.*
