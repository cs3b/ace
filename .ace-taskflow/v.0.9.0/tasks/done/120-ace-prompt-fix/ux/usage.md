# ace-prompt Usage After Fixes

## Overview

`ace-prompt` is a Ruby gem for enhancing prompts using LLM with intelligent caching, context loading, and archive management. After these fixes, it will reliably preserve user content while enhancing prompts with project context.

### Key Improvements
- Context embedding now preserves original prompt content
- Commands are testable and composable (no process termination)
- Proper archive versioning with _eXXX suffixes
- Nested prompt discovery works correctly
- Clear error messages for all failure modes

## Command Structure

```bash
ace-prompt process [options]
  --ace-context, -c      # Load project context via ace-context
  --enhance, -e          # Enhance prompt using LLM
  --raw, -r             # Skip enhancement (output as-is)
  --no-context, -n      # Skip context loading
  --task ID             # Process task-specific prompt

ace-prompt --help        # Show help message
ace-prompt --version     # Show version
```

## Usage Scenarios

### Scenario 1: Basic Prompt Enhancement
**Goal**: Improve clarity and specificity of a prompt without context

```bash
# Enhance the default prompt
$ ace-prompt process --enhance

# Output: Enhanced version of prompts/the-prompt.md
```

**Expected output**:
- Enhanced prompt content to stdout
- Original archived as `archive/YYYYMMDD-HHMMSS-the-prompt.md`
- Enhanced version archived as `archive/YYYYMMDD-HHMMSS-the-prompt_e001.md`

### Scenario 2: Context-Aware Enhancement (FIXED)
**Goal**: Enhance prompt with project context embedded

```bash
# Load context AND enhance - user content now preserved!
$ ace-prompt process --ace-context --enhance

# Or use short flags
$ ace-prompt process -ce
```

**Expected output**:
- Original prompt text preserved (BUG FIX)
- Context embedded with prompt
- Combined content enhanced by LLM
- Proper archive versioning visible immediately

### Scenario 3: Task-Specific Prompt Processing
**Goal**: Process a prompt for a specific task

```bash
# Process prompt for task 045
$ ace-prompt process --task 045 --enhance

# With context
$ ace-prompt process --task 045 --ace-context --enhance
```

**Expected output**:
- Uses prompt from task directory
- Applies same enhancement workflow
- Archives in task-specific location

### Scenario 4: View Raw Content with Context
**Goal**: See context expansion without enhancement

```bash
# Just load context, no enhancement
$ ace-prompt process --ace-context --raw

# Or explicitly skip enhancement
$ ace-prompt process -c --no-enhance
```

**Expected output**:
- Prompt with embedded context
- No LLM enhancement applied
- Useful for debugging context loading

### Scenario 5: Error Handling (IMPROVED)
**Goal**: Gracefully handle missing dependencies

```bash
# When ace-context gem is not available
$ ace-prompt process --ace-context --enhance
Warning: ace-context gem not available. Skipping context loading.
# Continues with enhancement only

# When prompt file doesn't exist
$ ace-prompt process --task 999
Error: Task 999 not found
# Returns exit code 1
```

## Command Reference

### `ace-prompt process`

**Syntax**: `ace-prompt process [options]`

**Parameters**:
- `--ace-context, -c`: Load project context using ace-context gem
- `--enhance, -e`: Enhance prompt using configured LLM
- `--raw, -r`: Output without enhancement
- `--no-context, -n`: Skip context loading even if configured
- `--task ID`: Use task-specific prompt instead of default

**Internal implementation**:
- Uses `Ace::Context.load_file(path, embed_source: true)` for context
- Calls ace-llm for enhancement with configured model
- Archives with timestamp and _eXXX iteration tracking

**Exit codes**:
- 0: Success
- 1: Error (missing file, configuration issue, etc.)

## Tips and Best Practices

### Archive Management
- Archives are created automatically in `prompts/archive/`
- Enhanced versions get _e001, _e002 suffixes
- Symlink `_previous.md` always points to last version
- Consider periodic cleanup of old archives

### Configuration
- Keep protocol configs in `.ace/nav/protocols/`
- Use `.ace.example/` for reference configurations only
- Configure default prompt location and archive settings

### Testing Integration
- Commands now return status codes for testing
- Can be composed in scripts without termination
- Use in CI/CD pipelines safely

### Performance
- Enhancement results are cached by content hash
- Repeated identical inputs return cached results
- Context loading adds ~100-200ms overhead
- LLM enhancement varies by model (1-5 seconds typical)

## Troubleshooting

### "Context not preserved in enhancement"
- **Fixed in this release**: The bug where context was lost is now resolved
- Verify with: `ace-prompt process -ce | grep "your original prompt text"`

### "Can't find nested prompts"
- **Fixed in this release**: Pattern updated from `*.md` to `**/*.md`
- Test with: `ace-nav prompt://ace-prompt/base/enhance`

### "Tests fail due to exit calls"
- **Fixed in this release**: Commands return status codes
- Test with: `ruby -r ./lib/ace/prompt/cli -e "p Ace::Prompt::CLI.new.process"`

### "Race condition in archives"
- **Fixed in this release**: Mutex added for thread-safety
- Safe for parallel execution

## Migration Notes

### From Previous Version
- **Key fix**: Context+enhancement now works correctly
- **Breaking change**: None - backward compatible
- **New behavior**: Archives created immediately with proper suffixes
- **Recommendation**: Re-run any prompts that need context+enhancement

### Configuration Changes
- Protocol config stays in `.ace/` (working configuration)
- Examples remain in `.ace.example/` (reference only)
- No action needed for existing configurations