---
id: v.0.9.0+task.037
status: done
priority: high
estimate: 1h
dependencies: [task.021]
---

# Add .env cascade loading support to ace-llm

## Behavioral Context

**Issue**: ace-llm-query couldn't find API keys from .env files like the original llm-query did. Users had to manually export environment variables.

**Key Behavioral Requirements**:
- Load .env files following ace cascade pattern
- Support both llm-specific and general .env files
- .ace/.env files should override system ENV variables (higher priority)
- Work without requiring mise or other external tools

## Objective

Implemented .env file loading for ace-llm using ace-core's EnvLoader, following the standard .ace cascade pattern for configuration discovery.

## Scope of Work

### Deliverables

#### Modify
- `ace-llm/lib/ace/llm/atoms/env_reader.rb` - Added `load_env_cascade` method
- `ace-llm/exe/ace-llm-query` - Added call to load .env files on startup

#### Create
- `ace-llm/.ace.example/llm/.env` - Example .env file with all supported API keys

## Implementation Summary

### What Was Done

- **Problem Identification**: Users reported "No API key found" errors despite having .env files
- **Investigation**: Found ace-llm only read from ENV directly, didn't load .env files
- **Solution**: Leveraged ace-core's existing EnvLoader and ConfigDiscovery for .env loading
- **Validation**: Confirmed .env files are loaded and override system ENV as requested

### Technical Details

Added cascade loading in EnvReader:
```ruby
def self.load_env_cascade
  return {} unless defined?(Ace::Core)

  discovery = Ace::Core::ConfigDiscovery.new

  # Look for llm-specific env files first
  llm_env_files = discovery.find_all_config_files("llm/.env")

  # Also check for general .ace/.env as fallback
  general_env_files = discovery.find_all_config_files(".env")

  # Load files (later files override earlier ones)
  all_files = (general_env_files + llm_env_files).uniq
  all_files.each do |file|
    next unless File.exist?(file)
    vars = Ace::Core::Molecules::EnvLoader.load_file(file)
    loaded_vars.merge!(vars) if vars
  end

  # Set with overwrite: true so .ace/.env has priority over ENV
  Ace::Core::Molecules::EnvLoader.set_environment(loaded_vars, overwrite: true)
end
```

### Cascade Search Order

The system searches for .env files in this order:
1. `./.ace/llm/.env` (current directory)
2. `../.ace/llm/.env` (parent directories up to project root)
3. `~/.ace/llm/.env` (user home)
4. `./.ace/.env` (general project config)
5. `~/.ace/.env` (general user config)

Files loaded later override earlier ones, and .ace/.env overrides system ENV.

### Testing/Validation

```bash
# Created test .env file
echo "TEST_PRIORITY=from_ace_env_file" > .ace/llm/.env

# Verified .ace/.env overrides ENV
TEST_PRIORITY=from_system_env ruby -I ace-core/lib -I ace-llm/lib \
  -e 'require "ace/llm"; Ace::LLM::Atoms::EnvReader.load_env_cascade;
      puts ENV["TEST_PRIORITY"]'
# Output: from_ace_env_file (correctly overrode system ENV)

# Verified API key loading
echo "GEMINI_API_KEY=test-key" > .ace/llm/.env
unset GEMINI_API_KEY && ./bin/ace-llm-query gflash "test"
# Got past "No API key found" error (hit API validation instead)
```

**Results**: .env files are loaded successfully with correct priority order

## References

- Related to: task.021 (Extract llm-query from dev-tools to ace-llm gem)
- Uses: ace-core's EnvLoader and ConfigDiscovery
- No new dependencies added (leverages existing ace-core)