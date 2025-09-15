# Self-Healing Error Messages Enhancement

## Intention

Enhance the existing `ErrorReporter` molecule to provide intelligent, self-healing error messages that automatically suggest corrections, show available options, and run help commands when errors occur.

## Problem It Solves

**Current Issues:**
- Generic error messages don't help users fix problems
- No automatic suggestions for common mistakes
- Missing context about available options
- Users must manually run --help to understand usage

**Impact:**
- Increased debugging time
- User frustration with cryptic errors
- Higher support burden
- Slower development cycles

## Solution Direction

### 1. Enhance Existing ErrorReporter

**Update `dev-tools/lib/coding_agent_tools/error_reporter.rb`:**
```ruby
module CodingAgentTools
  class ErrorReporter
    def report_with_suggestions(error, context = {})
      original_message = format_error(error)
      suggestions = generate_suggestions(error, context)
      help_text = fetch_help_text(context[:command])
      
      output_enhanced_error(original_message, suggestions, help_text)
    end
    
    private
    
    def generate_suggestions(error, context)
      case error
      when ModelNotFoundError
        suggest_available_models(context[:requested_model])
      when PathNotFoundError
        suggest_similar_paths(context[:path])
      when CommandError
        suggest_command_syntax(context[:command])
      end
    end
  end
end
```

### 2. Add Smart Suggestion Molecules

**New Molecules:**
```ruby
# dev-tools/lib/coding_agent_tools/molecules/model_suggester.rb
class ModelSuggester
  def suggest_models(requested)
    available = fetch_available_models
    fuzzy_matches = fuzzy_match(requested, available)
    
    {
      exact: available.select { |m| m.include?(requested) },
      similar: fuzzy_matches,
      aliases: find_aliases(requested)
    }
  end
end

# dev-tools/lib/coding_agent_tools/molecules/path_suggester.rb
class PathSuggester
  def suggest_paths(invalid_path)
    dirname = File.dirname(invalid_path)
    basename = File.basename(invalid_path)
    
    if Dir.exist?(dirname)
      similar_files = Dir.glob("#{dirname}/*").select do |f|
        levenshtein_distance(basename, File.basename(f)) < 3
      end
    end
    
    { similar: similar_files, parent_exists: Dir.exist?(dirname) }
  end
end
```

### 3. Integration with All CLI Tools

**Update all executables to use enhanced error reporting:**
```ruby
# dev-tools/lib/coding_agent_tools/cli/base.rb
module CodingAgentTools::CLI
  class Base < Dry::CLI::Command
    def call(**options)
      execute(options)
    rescue => e
      error_reporter.report_with_suggestions(e, 
        command: self.class.name,
        options: options
      )
      exit(1)
    end
  end
end
```

### 4. Example Enhanced Error Messages

**Before:**
```
Error: Model 'gpt-5' not found
```

**After:**
```
Error: Model 'gpt-5' not found

Did you mean one of these models?
  ✓ gpt-4o (OpenAI)
  ✓ gpt-4-turbo (OpenAI)
  ✓ gpt-3.5-turbo (OpenAI)

Available aliases:
  - gpt4 → openai:gpt-4o
  - gpt3 → openai:gpt-3.5-turbo

Usage: llm-query PROVIDER:MODEL "prompt"
Run 'llm-query --help' for more information
```

## Implementation Plan

### Phase 1: Core Enhancement (4 hours)
1. Enhance `ErrorReporter` class
2. Add suggestion generation logic
3. Integrate help text fetching

### Phase 2: Specific Suggesters (4 hours)
1. Implement `ModelSuggester`
2. Implement `PathSuggester`
3. Implement `CommandSuggester`

### Phase 3: Integration (2 hours)
1. Update all CLI tools
2. Add to base command class
3. Test with common errors

## Expected Benefits

- **50% reduction** in debugging time
- **Immediate fixes** for common typos
- **Self-documenting** error messages
- **Lower support burden**

## Success Metrics

- Error resolution time: 5 min → 1 min
- Support tickets: Reduce by 40%
- User satisfaction: Increase by 30%
- Adoption: 100% of tools use enhanced errors

## Dependencies

- Existing `ErrorReporter` class
- dry-cli framework
- All existing CLI tools

## Testing Strategy

- Unit tests for each suggester
- Integration tests for error scenarios
- User acceptance testing
- A/B testing old vs new errors
