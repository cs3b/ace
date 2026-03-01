---
id: 8nf000
title: "Retro: ace-context merge_contexts Bug Discovery"
type: conversation-analysis
tags: []
created_at: "2025-12-16 00:00:00"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8nf000-ace-context-merge-contexts-bug.md
---
# Retro: ace-context merge_contexts Bug Discovery

**Date**: 2025-12-16
**Context**: Pre-existing bug in ace-context that was masking the pr: feature implementation
**Author**: Claude Code
**Type**: Conversation Analysis | Bug Investigation

## Bug Description

The `merge_contexts` function in `ace-context/lib/ace/context/organisms/context_loader.rb` was silently discarding sections, commands, and content when merging contexts. This affected all presets using the `--preset` CLI flag.

### Symptoms

- `ace-context --preset pr` output only 11 lines / 179 bytes instead of expected 284+ lines
- Section-based presets appeared empty
- Metadata was output but no actual content

### Root Cause

The original `merge_contexts` function extracted only a subset of context data:

```ruby
context_hashes = contexts.map do |context|
  {
    files: context.files,
    metadata: context.metadata,
    preset_name: context.metadata[:preset_name],
    source_input: context.metadata[:source_input],
    errors: context.metadata[:errors] || []
  }
  # MISSING: sections, commands, content, diffs!
end
```

This meant:
- `context.sections` was never preserved
- `context.commands` was never preserved
- Processed content from sections (`_processed_files`, `_processed_commands`) was lost
- The resulting context used `OutputFormatter` (metadata-based) instead of `SectionFormatter`

## What Went Well

- Systematic debugging identified the exact line where data was being lost
- Direct Ruby API comparison (`load_auto` vs `load_multiple_inputs`) pinpointed the issue
- The fix maintained backward compatibility with legacy presets that expect metadata output

## Investigation Process

1. **Initial symptom**: `pr:` feature appeared broken
2. **Direct API test**: `GhPrExecutor.new(75).fetch_diff` worked correctly (854 lines)
3. **load_auto test**: `Ace::Context.load_auto("pr")` returned 8538 chars - correct!
4. **load_multiple_inputs test**: `Ace::Context.load_multiple_inputs(["pr"], [])` returned 179 bytes - broken!
5. **Traced the difference**: `load_multiple_inputs` calls `merge_contexts`, `load_auto` doesn't
6. **Found the bug**: `merge_contexts` was discarding sections

## Key Learnings

- **CLI and API can have different code paths**: The `--preset` flag uses `load_multiple_inputs` while positional arguments use `load_auto`
- **Test with actual CLI flags**: Unit tests may pass while CLI usage fails
- **Data preservation in merging**: When transforming data structures, verify ALL fields are preserved
- **Symptoms can be misleading**: The bug appeared as "pr: feature broken" but was actually "all sections broken"

## The Fix

Added conditional handling for single vs multiple contexts:

```ruby
def merge_contexts(contexts)
  return Models::ContextData.new if contexts.empty?

  # Single context with actual processed section content: preserve sections
  if contexts.size == 1 && has_processed_section_content?(contexts.first)
    result = contexts.first
    result.metadata[:merged] = true
    result.metadata[:total_contexts] = 1
    result.metadata[:sources] = [result.metadata[:preset_name] || result.metadata[:source_path]].compact
    return format_context(result, @options[:format] || 'markdown-xml')
  end

  # Default path: use original merge logic for backward compatibility
  # (preserves metadata-based output for legacy presets)
  ...
end
```

Added helper to distinguish real sections from auto-migrated ones:

```ruby
def has_processed_section_content?(context)
  return false unless context.has_sections?

  context.sections.any? do |_name, data|
    processed_files = data[:_processed_files] || data['_processed_files'] || []
    processed_commands = data[:_processed_commands] || data['_processed_commands'] || []
    processed_files.any? || processed_commands.any?
  end
end
```

## Action Items

### Stop Doing

- Assuming CLI flags use same code path as direct API calls
- Extracting subset of fields without checking what's lost

### Continue Doing

- Comparing Ruby API vs CLI output when debugging
- Tracing through code paths with debug output

### Start Doing

- Add integration tests that use actual CLI flags (`--preset`, `-p`, `-f`)
- Consider adding a "data preservation" test that verifies all context fields survive merging
- Document the different code paths for preset loading

## Impact Assessment

**Severity**: Medium-High
- All section-based presets were affected
- Only triggered when using `--preset` flag (not positional argument)
- Silently produced truncated output (no errors)

**Duration**: Unknown (pre-existing)
- Bug existed before this session
- Likely introduced when section-based formatting was added

## Technical Details

### Affected Code Path

```
CLI: ace-context --preset NAME
  → load_multiple_inputs(["NAME"], [], options)
    → load_from_preset_config(preset, merged_options)  # Returns context WITH sections
    → contexts << context
  → merge_contexts(contexts)  # BUG: Discards sections!
    → format_context(result, format)  # Uses OutputFormatter (no sections)
```

### Working Code Path

```
CLI: ace-context NAME
  → load_auto("NAME")
    → load_preset("NAME")
      → load_from_preset_config(preset, merged_options)
      → format_context(context, format)  # Uses SectionFormatter (has sections)
```

## Additional Context

- Related to Task 145.01: Add pr: support to ace-context
- The pr: feature implementation was correct but masked by this bug
- Fix maintains backward compatibility - legacy presets still get metadata-based output
