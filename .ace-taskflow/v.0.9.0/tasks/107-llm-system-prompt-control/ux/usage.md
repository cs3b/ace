# System Prompt Control in ace-llm-query

## Overview

Enhanced system prompt control for ace-llm-query that provides:
- Full control over system prompts with `--system` flag (replaces defaults)
- Ability to append to defaults with `--system-append` flag (keeps helpful context)
- Provider-specific mapping to native capabilities
- Backward compatibility with existing usage

## Command Structure

### Basic System Prompt Control
```bash
# Replace default system prompt entirely
ace-llm-query claude:haiku --system custom-prompt.md --prompt "Your question"

# Append to default system prompt
ace-llm-query claude:haiku --system-append extra-context.md --prompt "Your question"

# Use both for layered control
ace-llm-query claude:haiku --system base.md --system-append context.md --prompt "Your question"
```

### Provider Behavior

**Claude (via Claude Code CLI)**:
- `--system` → maps to `--system-prompt` (replaces defaults)
- `--system-append` → maps to `--append-system-prompt` (adds to defaults)

**API Providers (Anthropic, OpenAI, Google)**:
- Both flags concatenate into single system message
- Clear separator between sections when both used

## Usage Scenarios

### Scenario 1: Precise Commit Message Generation
**Goal**: Generate focused commit messages without verbose explanations

```bash
# Create minimal system prompt for commits
echo "Generate a concise commit message following conventional commit format. Output ONLY the commit message, no explanations." > commit-prompt.md

# Use with ace-git-commit (indirectly)
ace-llm-query claude:haiku --system commit-prompt.md --prompt "$(git diff --staged)"

# Expected output:
# fix: correct ClaudeCodeClient system flag usage
```

### Scenario 2: Enhanced Code Review with Context
**Goal**: Review code with additional project-specific context

```bash
# Keep Claude's helpful defaults but add project context
echo "This project follows ATOM architecture. Focus on separation of concerns." > project-context.md

ace-llm-query claude:sonnet --system-append project-context.md --prompt "Review this Ruby class: $(cat lib/my_class.rb)"

# Claude's defaults remain active (helpful, harmless, honest)
# PLUS your project-specific guidance
```

### Scenario 3: Layered System Prompts
**Goal**: Base instructions plus task-specific context

```bash
# Base coding standards
echo "Follow Ruby style guide. Use descriptive variable names." > base-standards.md

# Task-specific context
echo "This is a CLI tool. Focus on user experience and error messages." > cli-context.md

ace-llm-query claude:haiku \
  --system base-standards.md \
  --system-append cli-context.md \
  --prompt "Write a Thor command class for file processing"
```

### Scenario 4: Testing Provider Differences
**Goal**: Verify how different providers handle system prompts

```bash
# Test with Claude (supports both flags)
ace-llm-query claude:haiku --system test.md --system-append append.md --prompt "Test"
# Uses --system-prompt and --append-system-prompt

# Test with OpenAI (single system message)
ace-llm-query openai:gpt-4 --system test.md --system-append append.md --prompt "Test"
# Concatenates both into one system message

# Test with direct Anthropic API
ace-llm-query anthropic:haiku --system test.md --prompt "Test"
# Uses system parameter in API call
```

### Scenario 5: Debugging System Prompt Issues
**Goal**: Verify system prompts are being used correctly

```bash
# Test current broken state (before fix)
ace-llm-query claude:haiku --system "You are a pirate" --prompt "Say hello" --debug
# ERROR: Would show --system flag not recognized

# Test after fix
ace-llm-query claude:haiku --system "You are a pirate" --prompt "Say hello" --debug
# Success: "Ahoy there, matey!"

# Verify append functionality
ace-llm-query claude:haiku \
  --system "You are a helpful assistant" \
  --system-append "Respond in haiku format" \
  --prompt "Describe Ruby"
# Output in haiku format
```

## Command Reference

### ace-llm-query Flags

**System Prompt Flags**:
- `--system FILE_OR_TEXT` - Replace default system prompt entirely
- `--system-append FILE_OR_TEXT` - Append to existing/default system prompt

**Implementation Details**:
- Both flags support file paths (detected by .md, .txt extensions or / in path)
- Text without file markers is used directly
- File paths are read via FileIoHandler with proper error handling

### Provider-Specific Mapping

**ClaudeCodeClient** (claude:* models):
```ruby
# When --system is provided:
cmd << "--system-prompt" << system_content

# When --system-append is provided:
cmd << "--append-system-prompt" << append_content
```

**API Providers** (anthropic:*, openai:*, google:*):
```ruby
# Concatenate with clear separator
system_message = [
  options[:system_prompt],
  "---",  # Clear separator
  options[:append_system_prompt]
].compact.join("\n\n")
```

## Tips and Best Practices

1. **Use --system for deterministic outputs** - When you need exact control (commits, formatting)
2. **Use --system-append for enhancements** - When defaults are helpful but need additions
3. **Test with --debug flag** - Verify your system prompts are being used correctly
4. **File paths are auto-detected** - Any string with `/`, `.md`, or `.txt` is treated as a file
5. **Combine for complex scenarios** - Use both flags for base + context layering

## Migration from Previous Behavior

**Before** (broken):
```bash
ace-llm-query claude:haiku --system my-prompt.md --prompt "Question"
# Would fail silently or error
```

**After** (fixed):
```bash
ace-llm-query claude:haiku --system my-prompt.md --prompt "Question"
# Works correctly, maps to --system-prompt
```

**New capability**:
```bash
ace-llm-query claude:haiku --system-append context.md --prompt "Question"
# Adds to defaults instead of replacing
```

## Troubleshooting

**System prompt not working?**
- Check provider supports system prompts: `ace-llm-query --list-providers`
- Use `--debug` to see actual command being executed
- Verify file exists if using file path

**Getting default responses despite --system?**
- Ensure you're using latest ace-llm-providers-cli version
- Check if provider requires --system-append instead
- Some models have strong default behaviors that need explicit overriding

**File not found errors?**
- Use absolute paths or paths relative to current directory
- Check file permissions
- Verify path doesn't contain special characters that need escaping