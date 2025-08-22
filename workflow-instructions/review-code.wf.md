# Code Review Workflow Instruction

## Goal

Perform comprehensive code review using the modernized `code-review` command with preset configurations, modular prompt composition, and automated execution for streamlined development workflows.

## ⚠️ CRITICAL: AI Agent Instructions ⚠️

**FOR AI CODING AGENTS - READ THIS FIRST**

This workflow now uses the simplified single-command `code-review` tool with `--auto-execute`. The tool handles all complexity internally.

### What TO DO:
1. **Select appropriate preset** or compose custom configuration
2. **Execute code-review** with `--auto-execute` flag
3. **Review generated report** for insights and actions

### What NOT TO DO:
- ❌ Use Read tool on individual source files
- ❌ Manually run llm-query (handled by --auto-execute)
- ❌ Create tasks (user's responsibility after reviewing reports)
- ❌ Use the old multi-step workflow (deprecated)

## Prerequisites

- Access to `code-review` command (v2.0+)
- LLM provider access configured (default: google:gemini-2.0-flash-exp)
- Understanding of available presets and modular prompt system
- Git wrapper tools (`git-diff`, `git-log`, etc.)
- Optional: Context configuration files in dev-taskflow/

## Quick Start Examples

### 🚀 Most Common Scenarios

```bash
# 1. Daily PR Review (most common)
code-review --preset pr --auto-execute

# 2. Pre-commit Review
code-review --preset code --subject 'commands: ["git-diff --staged"]' --auto-execute

# 3. Architecture Compliance Check (Ruby ATOM)
code-review --preset ruby-atom-modular --auto-execute

# 4. Security Audit
code-review --preset security --auto-execute

# 5. Multi-Repository Review
code-review \
  --preset pr \
  --subject 'commands: ["git-diff HEAD~1", "git-diff -C dev-handbook HEAD~1", "git-diff -C dev-tools HEAD~1"]' \
  --auto-execute

# 6. Custom Review with Focus Areas
code-review \
  --preset code \
  --add-focus 'quality/performance,quality/security' \
  --auto-execute
```

## Available Presets (14 Total)

### Core Review Presets
- **`pr`** - Pull request review with project context and standard format
- **`code`** - Code quality and architecture review
- **`docs`** - Documentation review with docs-specific focus
- **`test`** - Test coverage and quality review

### Architecture-Specific Presets
- **`ruby-atom-modular`** - Ruby ATOM architecture review (Atoms→Molecules→Organisms)
- **`rails-modular`** - Rails application review with framework patterns
- **`vue-firebase-modular`** - Vue.js Firebase PWA review

### Quality-Focused Presets
- **`security`** - Security and vulnerability review
- **`security-focused`** - Detailed security audit with comprehensive checks
- **`performance`** - Performance and optimization review
- **`performance-focused`** - Detailed performance analysis

### Specialized Presets
- **`agents`** - AI agent definition review
- **`full-stack`** - Comprehensive review with tests and docs
- **`quick-review`** - Compact review for small changes

## Modular Prompt Composition System

### Understanding the 4-Layer System

Prompts are composed from modular components in 4 layers:

1. **Base Module** (`--prompt-base`)
   - `system` - Standard code review prompt (default)
   - `sections` - Structured section-based review

2. **Format Module** (`--prompt-format`)
   - `standard` - Balanced detail level (default)
   - `detailed` - Comprehensive analysis
   - `compact` - Concise summary

3. **Focus Modules** (`--prompt-focus` or `--add-focus`)
   - **Architecture**: `architecture/atom`
   - **Languages**: `languages/ruby`
   - **Frameworks**: `frameworks/rails`, `frameworks/vue-firebase`
   - **Quality**: `quality/security`, `quality/performance`
   - **Scope**: `scope/tests`, `scope/docs`

4. **Guidelines** (`--prompt-guidelines`)
   - `tone` - Professional review tone
   - `icons` - Use emoji indicators for clarity

### Custom Prompt Composition Examples

```bash
# Combine preset with additional focus areas
code-review --preset ruby-atom-modular --add-focus 'quality/security,scope/tests' --auto-execute

# Build custom review from scratch
code-review \
  --prompt-base system \
  --prompt-format detailed \
  --prompt-focus 'architecture/atom,languages/ruby,quality/performance' \
  --prompt-guidelines 'tone,icons' \
  --auto-execute

# Override preset's format
code-review --preset pr --prompt-format detailed --auto-execute
```

## Using Context Files for Complex Reviews

### Context File Structure

Create a context file (e.g., `dev-taskflow/current/*/docs/code-review-contexts.md`):

```markdown
subject: diff from sha till HEAD on following repos

[main]         8e7882c chore: update submodules after review
[dev-handbook] 0567c83 feat(code-review): implement preset config
[dev-tools]    df8f6e2 refactor(cli): redesign code-review

context:
- presets: project, dev-handbook, dev-tools

- context for system prompt:
    dev-handbook/templates/review-modules/focus/architecture/atom.md
    dev-handbook/templates/review-modules/focus/languages/ruby.md
    dev-handbook/templates/review-modules/format/detailed.md
```

### Using Context Files

```bash
# Reference context file for review parameters
code-review \
  --config-file dev-taskflow/current/v.0.5.0/docs/code-review-contexts.md \
  --auto-execute

# Or extract parameters manually and use them
code-review \
  --context 'presets: [project, dev-handbook, dev-tools]' \
  --subject 'commands: ["git-diff 8e7882c~1..HEAD"]' \
  --prompt-focus 'architecture/atom,languages/ruby' \
  --prompt-format detailed \
  --auto-execute
```

## Session Management

### Session Files (Default Behavior)

```bash
# Default: saves session for debugging
code-review --preset pr --auto-execute
# Creates: dev-taskflow/current/*/code_review/session-*/

# Skip session files for faster execution
code-review --preset pr --no-save-session --auto-execute

# Custom session location
code-review --preset pr --session-dir ./my-review --auto-execute
```

### Session Directory Contents
- `prompt.md` - Combined prompt sent to LLM
- `cr-report-*.md` - Generated review report
- `context/` - Loaded context files
- `subject/` - Files/diffs being reviewed

## Multi-Repository Review Patterns

### Reviewing Submodule Changes

```bash
# Review main repo + all submodules
code-review \
  --preset pr \
  --subject 'commands: [
    "git-diff HEAD~1",
    "git-diff -C dev-handbook HEAD~1",
    "git-diff -C dev-tools HEAD~1",
    "git-diff -C dev-taskflow HEAD~1"
  ]' \
  --auto-execute

# Review specific submodule with its context
code-review \
  --preset ruby-atom-modular \
  --context 'presets: [project, dev-tools]' \
  --subject 'commands: ["git-diff -C dev-tools HEAD~5"]' \
  --auto-execute
```

### Cross-Repository Dependencies

```bash
# Review interface changes across repos
code-review \
  --prompt-focus 'architecture/atom' \
  --context 'files: [
    "dev-handbook/templates/**/*.md",
    "dev-tools/lib/**/cli/**/*.rb"
  ]' \
  --subject 'commands: ["git-diff HEAD~1 -- **/cli/**"]' \
  --auto-execute
```

## Configuration File Approach

### YAML Front Matter in Markdown

Create a review configuration file:

```markdown
---
preset: ruby-atom-modular
model: google:gemini-2.0-flash-exp
context:
  presets: [project, dev-tools]
subject:
  commands:
    - git-diff HEAD~1
    - git-diff -C dev-tools HEAD~1
add_focus: 'quality/security,quality/performance'
auto_execute: true
output: ./security-review.md
---

# Security Review Configuration

This reviews recent changes for security implications.
```

### Using Configuration Files

```bash
# Use configuration file
code-review --config-file review-configs/security-audit.md

# Override config file settings
code-review --config-file review-configs/pr-review.md --model anthropic:claude-3
```

## Common Workflow Patterns

### Developer Daily Workflow

```bash
# Morning: Review overnight PRs
code-review --preset pr --auto-execute

# Before commit: Review staged changes
code-review --preset code --subject 'commands: ["git-diff --staged"]' --auto-execute

# Before merge: Security check
code-review --preset security-focused --auto-execute
```

### CI/CD Integration

```bash
# Automated PR review
code-review \
  --preset pr \
  --no-save-session \
  --output pr-review-${PR_NUMBER}.md \
  --auto-execute

# Architecture compliance check
code-review \
  --preset ruby-atom-modular \
  --add-focus 'quality/security' \
  --output compliance-report.md \
  --auto-execute
```

### Team Review Patterns

```bash
# Comprehensive team review
code-review \
  --preset full-stack \
  --context 'presets: [project, dev-handbook, dev-tools]' \
  --subject 'commands: ["git-diff origin/main..HEAD"]' \
  --output team-review-$(date +%Y%m%d).md \
  --auto-execute
```

## Process Steps (Simplified Workflow)

### 1. **Choose Review Strategy**

#### Option A: Use a Preset
```bash
# Select from 14 available presets
code-review --list-presets  # See all options
code-review --preset [preset-name] --auto-execute
```

#### Option B: Compose Custom Review
```bash
code-review \
  --prompt-base system \
  --prompt-format [standard|detailed|compact] \
  --prompt-focus '[focus-modules]' \
  --context '[context-spec]' \
  --subject '[subject-spec]' \
  --auto-execute
```

#### Option C: Use Configuration File
```bash
code-review --config-file [path-to-config] --auto-execute
```

### 2. **Define Context (What Background to Include)**

```yaml
# Use preset contexts
context: 'project'  # or 'dev-tools', 'dev-handbook'

# Multiple presets
context: 'presets: [project, dev-tools]'

# Specific files
context: 'files: ["docs/architecture.md", "README.md"]'

# Commands output
context: 'commands: ["task-manager list", "git-log --oneline -10"]'
```

### 3. **Define Subject (What to Review)**

```yaml
# Git diff ranges
subject: 'HEAD~5..HEAD'  # Last 5 commits
subject: 'origin/main..HEAD'  # PR changes
subject: 'commands: ["git-diff --staged"]'  # Staged changes

# Specific files
subject: 'files: ["lib/**/*.rb", "spec/**/*.rb"]'

# Multiple sources
subject: 'commands: [
  "git-diff HEAD~1",
  "git-diff -C dev-tools HEAD~1"
]'

### 4. **Execute Review**

```bash
# Everything happens automatically with --auto-execute
code-review [configuration] --auto-execute

# Or prepare for manual review
code-review [configuration] --dry-run  # See what would happen
code-review [configuration]  # Prepare without executing
```

**What Happens Internally:**
1. Context files are loaded and combined
2. Subject (diffs/files) are collected
3. Prompt modules are composed
4. LLM query executes with 600s timeout
5. Report is generated and saved

### 5. **Review Output**

```bash
# Default output location
./code-review-TIMESTAMP.md

# Custom output
code-review --preset pr --output ./reviews/pr-123.md --auto-execute

# Stream to console (no file)
code-review --preset pr --output - --auto-execute
```

**Report Structure:**
- Executive summary with key findings
- Detailed analysis by category
- Specific line-by-line feedback
- Actionable recommendations
- Recognition of good practices

## Best Practices

### 1. **Start Simple, Add Complexity**
```bash
# Start with a preset
code-review --preset pr --auto-execute

# Add custom focus if needed
code-review --preset pr --add-focus 'quality/security' --auto-execute

# Eventually create custom configuration
code-review --config-file my-review-config.md --auto-execute
```

### 2. **Use Appropriate Presets**
- **Daily work**: `pr`, `code`, `quick-review`
- **Architecture**: `ruby-atom-modular`, `rails-modular`
- **Quality gates**: `security-focused`, `performance-focused`
- **Comprehensive**: `full-stack`, `agents`

### 3. **Optimize for Speed**
```bash
# Fast execution without session files
code-review --preset quick-review --no-save-session --auto-execute

# Cached context for repeated reviews
code-review --context 'presets: [project]' --auto-execute
```

### 4. **Debug When Needed**
```bash
# Keep session for debugging
code-review --preset pr --save-session --debug

# Check what would be done
code-review --preset pr --dry-run
```

## Command Reference

### Primary Command Options

```bash
code-review [OPTIONS]
```

| Option | Description | Example |
|--------|-------------|---------|
| `--preset` | Use predefined configuration | `--preset pr` |
| `--context` | Background information (YAML or preset) | `--context 'presets: [project]'` |
| `--subject` | What to review (YAML or git range) | `--subject HEAD~5..HEAD` |
| `--prompt-base` | Base module for prompt | `--prompt-base system` |
| `--prompt-format` | Format style | `--prompt-format detailed` |
| `--prompt-focus` | Focus areas (comma-separated) | `--prompt-focus 'architecture/atom,languages/ruby'` |
| `--add-focus` | Add focus to preset | `--add-focus 'quality/security'` |
| `--model` | LLM model to use | `--model google:gemini-2.0-flash-exp` |
| `--auto-execute` | Run LLM query immediately | `--auto-execute` |
| `--no-save-session` | Skip session files | `--no-save-session` |
| `--output` | Output file path | `--output review.md` |
| `--config-file` | Configuration file | `--config-file config.md` |
| `--list-presets` | Show available presets | `--list-presets` |
| `--dry-run` | Show without executing | `--dry-run` |
| `--debug` | Enable debug output | `--debug` |

## Real-World Examples

### Scenario 1: Morning PR Review
```bash
# Review all changes in PR against main branch
code-review --preset pr --auto-execute

# With custom output location
code-review --preset pr --output reviews/pr-$(date +%Y%m%d).md --auto-execute
```

### Scenario 2: Pre-Commit Security Check
```bash
# Quick security review of staged changes
code-review \
  --preset security \
  --subject 'commands: ["git-diff --staged"]' \
  --output - \
  --auto-execute
```

### Scenario 3: Architecture Compliance Review
```bash
# Review Ruby code for ATOM architecture compliance
code-review \
  --preset ruby-atom-modular \
  --context 'presets: [project, dev-tools]' \
  --subject 'files: ["lib/**/*.rb"]' \
  --add-focus 'scope/tests' \
  --auto-execute
```

### Scenario 4: Multi-Repository Feature Review
```bash
# Review feature implementation across all repos
code-review \
  --prompt-base system \
  --prompt-format detailed \
  --prompt-focus 'architecture/atom,languages/ruby,scope/tests' \
  --context 'presets: [project, dev-handbook, dev-tools]' \
  --subject 'commands: [
    "git-diff origin/main..feature-branch",
    "git-diff -C dev-handbook origin/main..feature-branch",
    "git-diff -C dev-tools origin/main..feature-branch"
  ]' \
  --output feature-review.md \
  --auto-execute
```

### Scenario 5: Using Context Configuration File
```bash
# Create context file first
cat > review-context.md << 'EOF'
subject: diff from sha till HEAD on following repos
[main]         8e7882c chore: update submodules
[dev-handbook] 0567c83 feat: implement preset config
[dev-tools]    df8f6e2 refactor: redesign command

context:
- presets: project, dev-handbook, dev-tools
- focus modules:
    - architecture/atom
    - languages/ruby
    - quality/security
EOF

# Use the context file
code-review \
  --config-file review-context.md \
  --preset ruby-atom-modular \
  --auto-execute
```

## Success Criteria

- ✅ Appropriate preset or configuration selected
- ✅ Context properly loaded (project docs, architecture, etc.)
- ✅ Subject correctly identified (diffs, files, or commands)
- ✅ code-review command executes with --auto-execute
- ✅ LLM query completes within timeout (600s)
- ✅ Review report generated with actionable feedback
- ✅ Output saved to specified location or default
- ✅ No manual llm-query execution needed
- ✅ No tasks created (user reviews report and decides)

## Troubleshooting

### Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| "Preset not found" | Run `code-review --list-presets` to see available options |
| "Context loading failed" | Check file paths in context specification |
| "Git diff empty" | Verify git range or use `git-diff` to test |
| "LLM timeout" | Review is too large; narrow the scope |
| "No output generated" | Add `--debug` flag to see detailed execution |
| "Session files missing" | Remove `--no-save-session` flag |

### Debug Commands

```bash
# See what would be executed
code-review --preset pr --dry-run

# Keep session for investigation
code-review --preset pr --save-session --debug

# Check preset configuration
grep -A 20 "preset_name:" .coding-agent/code-review.yml
```

## Summary

The modern `code-review` command streamlines code review through:

1. **14 Presets** for common review scenarios
2. **Modular Prompt Composition** for custom reviews
3. **Single-Command Execution** with `--auto-execute`
4. **Multi-Repository Support** for complex projects
5. **Configuration Files** for repeatable reviews

**Remember**: This workflow generates review reports only. Task creation and action items are the user's responsibility after reviewing the generated reports.

---

*Last Updated: Workflow modernized to use single-command approach with preset configurations and modular prompt composition.*