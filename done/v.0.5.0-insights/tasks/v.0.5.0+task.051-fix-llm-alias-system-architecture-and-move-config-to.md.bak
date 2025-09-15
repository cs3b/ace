---
id: v.0.5.0+task.051
status: done
priority: high
estimate: 2 hours
dependencies: [v.0.5.0+task.048]
---

# Fix LLM alias system architecture and move config to dotfiles

## Behavioral Context

**Issue**: The LLM alias configuration was incorrectly placed as a hardcoded file within the gem (`dev-tools/config/default-llm-aliases.yml`), preventing project-specific customization and not following the established dotfile pattern used by other configuration files.

**Key Behavioral Requirements**:
- Aliases must be configurable per project via `.coding-agent/llm-aliases.yml`
- System must work regardless of current working directory within project
- `llm-query cc` should display available aliases instead of erroring
- Claude Code aliases (`opus`, `sonnet`, `haiku`) must work properly

## Objective

Restructure the LLM alias system to follow the project's established dotfile pattern, enabling project-specific alias configuration and fixing bugs in the Claude Code provider.

## Scope of Work

- Created dotfile template for LLM aliases
- Fixed alias resolution to use ProjectRootDetector
- Fixed ClaudeCodeClient missing method error
- Added alias display functionality to llm-query
- Removed wrongly placed config file from gem

### Deliverables

#### Create
- `dev-handbook/.meta/tpl/dotfiles/llm-aliases.yml` - Template for project aliases
- `.coding-agent/llm-aliases.yml` - Installed project configuration

#### Modify
- `dev-tools/lib/coding_agent_tools/molecules/llm_alias_resolver.rb` - Added ProjectRootDetector integration
- `dev-tools/lib/coding_agent_tools/organisms/claude_code_client.rb` - Added missing normalize_model_name method
- `dev-tools/lib/coding_agent_tools/cli/commands/llm/query.rb` - Added alias display functionality

#### Delete
- `dev-tools/config/default-llm-aliases.yml` - Removed wrongly placed config

## Implementation Summary

### What Was Done

- **Problem Identification**: Discovered during testing that `llm-query opus` failed with missing method error, and configuration was hardcoded in gem
- **Investigation**: Found that config was in wrong location and not following dotfile pattern
- **Solution**: 
  1. Created proper dotfile template in handbook
  2. Updated LlmAliasResolver to use ProjectRootDetector for finding config
  3. Fixed ClaudeCodeClient by adding missing method
  4. Enhanced llm-query to show aliases when no prompt given
- **Validation**: Tested aliases work from any directory within project

### Technical Details

**LlmAliasResolver Load Order**:
```ruby
1. .coding-agent/llm-aliases.yml (project-specific via ProjectRootDetector)
2. ~/.config/coding-agent-tools/llm-aliases.yml (user global)
3. Minimal hardcoded defaults (emergency fallback)
```

**ClaudeCodeClient Fix**:
```ruby
def normalize_model_name(model)
  # Map aliases to actual model names, or pass through
  AVAILABLE_MODELS[model] || model
end
```

**Alias Display Feature**:
When running `llm-query cc` without a prompt, now displays:
- Global aliases that map to the provider
- Provider-specific aliases
- Usage examples

### Testing/Validation

```bash
# Test showing aliases
llm-query cc  # Shows available Claude aliases

# Test alias functionality
llm-query opus "Hello"  # Works with Claude
llm-query gflash "Hello"  # Works with Google

# Test custom project alias
echo 'mytest: "google:gemini-2.5-flash"' >> .coding-agent/llm-aliases.yml
llm-query mytest "Test"  # Works from any directory in project
```

**Results**: All aliases work correctly, custom project aliases are loaded properly, and the system falls back to defaults when outside project context.

## References

- Related to: v.0.5.0+task.048 (original alias implementation)
- Commits: Fixed architecture issues from initial implementation
- Follow-up needed: None - system now works as intended