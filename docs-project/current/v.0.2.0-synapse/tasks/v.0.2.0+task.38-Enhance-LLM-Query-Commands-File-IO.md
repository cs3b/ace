---
id: v.0.2.0+task.38
title: Enhance LLM Query Commands File I/O and Format Handling
status: pending
priority: high
assignee: unassigned
labels:
  - enhancement
  - cli
  - user-experience
estimated_hours: 12
actual_hours: 0
created_at: 2024-01-01
updated_at: 2024-01-01
---

# Enhance LLM Query Commands File I/O and Format Handling

## Objective / Problem Statement

The current LLM query commands (`llm-gemini-query`, `llm-lmstudio-query`) have inconsistent and limited file I/O capabilities. Users need to be able to easily run prompts from files, save outputs in various formats, and have a more intuitive command-line interface. The current `--file` flag behavior is confusing, and there's no support for structured output formats like markdown with metadata or plain text.

## Directory Audit

```bash
find exe -name "*query*" -type f
# exe/llm-gemini-query
# exe/llm-lmstudio-query

find lib -name "*query*" -type f
# lib/coding_agent_tools/cli/commands/llm/query.rb
# lib/coding_agent_tools/cli/commands/lms/query.rb
```

## Scope of Work

- Redesign command-line interface for better file I/O handling
- Add support for reading prompts and system prompts from files with auto-detection
- Implement multiple output formats (JSON, Markdown, Plain text)
- Add automatic format inference from file extensions with explicit override
- Include normalized metadata in structured formats with execution timing
- Remove confusing `--file` flag in favor of explicit options
- Update all relevant documentation

## Deliverables / Manifest

- [ ] Update `exe/llm-gemini-query` with new CLI interface
- [ ] Update `exe/llm-lmstudio-query` with new CLI interface
- [ ] Create shared file I/O module for consistency
- [ ] Create format handlers for JSON, Markdown, and Plain text
- [ ] Create metadata normalization module
- [ ] Update command documentation and help text
- [ ] Add integration tests for file I/O scenarios
- [ ] Update documentation in `docs/` and root `*.md` files

## Implementation Plan

### Planning Steps

* [ ] Design new CLI interface with explicit file handling
  ```bash
  # New interface examples:
  llm-gemini-query path/to/prompt.md --system path/to/system.md --output path/to/output.json --format json
  llm-gemini-query "inline prompt" --output result.md  # infers markdown from extension
  llm-gemini-query path/to/prompt.txt --system "inline system prompt" --output summary.txt
  ```

* [ ] Design auto-format detection logic
  - File path detection: Check if argument is a valid file path to determine file vs inline content
  - Format precedence: `--format` flag takes precedence over file extension inference
  - Support both file and inline content for `--prompt` and `--system` flags

* [ ] Design metadata normalization structure
  ```json
  {
    "text": "response content",
    "metadata": {
      "finish_reason": "stop|length|error",
      "input_tokens": 123,
      "output_tokens": 456,
      "took": 2.45,
      "provider": "gemini|lmstudio",
      "model": "model-name",
      "timestamp": "2024-01-01T12:00:00Z"
    }
  }
  ```

* [ ] Plan format handlers architecture
  - JSON: Full metadata with normalized token counts
  - Markdown: YAML front matter + content
  - Plain text: Content only, metadata in summary when writing to file

* [ ] Identify current `--file` flag cleanup areas
  - Remove `--file` option from both command classes
  - Update `PromptProcessor.process` method signature
  - Remove `from_file` parameter usage
  - Update related tests

### Execution Steps

- [ ] Create shared file I/O module (`Molecules::FileIOHandler`)
  - [ ] Implement file reading utilities with path validation
  - [ ] Implement file writing utilities with directory creation
  - [ ] Add format inference from file extensions
  - [ ] Add path detection logic (file vs inline content)
  > TEST: File Path Detection
  >   Type: Unit Test
  >   Assert: Correctly identifies file paths vs inline content
  >   Command: bundle exec rspec spec/coding_agent_tools/molecules/file_io_handler_spec.rb

- [ ] Create metadata normalization module (`Molecules::MetadataNormalizer`)
  - [ ] Implement provider-specific token mapping
    - Gemini: `promptTokenCount` → `input_tokens`, `candidatesTokenCount` → `output_tokens`
    - LMStudio: `prompt_tokens` → `input_tokens`, `completion_tokens` → `output_tokens`
  - [ ] Add execution timing tracking
  - [ ] Add common metadata fields (provider, model, timestamp)

- [ ] Create format handler modules
  - [ ] JSON format handler with normalized metadata
  - [ ] Markdown format handler with YAML front matter
  - [ ] Plain text format handler (content only)
  - [ ] Add summary generation for file output scenarios

- [ ] Remove current `--file` flag implementation
  - [ ] Update CLI argument parsing in both query commands
  - [ ] Remove `--file` option definitions
  - [ ] Update `process_prompt` methods to use auto-detection
  - [ ] Update help text and examples
  > TEST: CLI Argument Parsing
  >   Type: Unit Test
  >   Assert: New argument structure parses correctly, old --file flag removed
  >   Command: bundle exec rspec spec/coding_agent_tools/cli/commands/llm/query_spec.rb spec/coding_agent_tools/cli/commands/lms/query_spec.rb

- [ ] Implement new CLI interface
  - [ ] Replace `--file` with auto-detection logic
  - [ ] Add `--system` file support (extends existing inline support)
  - [ ] Add `--output` flag for output file path
  - [ ] Add `--format` flag with auto-inference fallback
  - [ ] Make first positional argument support both inline and file content

- [ ] Implement file-based content handling
  - [ ] Auto-detect file vs inline content for prompt argument
  - [ ] Auto-detect file vs inline content for `--system` argument
  - [ ] Support both absolute and relative paths
  - [ ] Handle file reading errors gracefully

- [ ] Implement output file handling
  - [ ] Create output directory if it doesn't exist
  - [ ] Write output in specified or inferred format
  - [ ] Print execution summary to stdout when writing to file
  - [ ] Handle file writing errors gracefully
  > TEST: File Output Creation
  >   Type: Integration Test
  >   Assert: Output files created with correct format and metadata
  >   Command: bundle exec rspec spec/integration/llm_file_io_integration_spec.rb

- [ ] Add format-specific features
  - [ ] JSON: Include normalized metadata (input_tokens, output_tokens, took, etc.)
  - [ ] Markdown: Add YAML front matter with metadata
  - [ ] Plain text: Save only response content, show summary in stdout
  - [ ] Add execution timing to all formats

- [ ] Update help text and documentation
  - [ ] Clear examples in `--help` output for both commands
  - [ ] Update command documentation in `docs/llm-integration/`
  - [ ] Scan and update references in `docs/**/*.md` and root `*.md` files
  - [ ] Remove `--file` flag references from documentation

- [ ] Apply changes consistently
  - [ ] Update `llm-gemini-query` command
  - [ ] Update `llm-lmstudio-query` command
  - [ ] Ensure identical interface behavior across providers
  - [ ] Maintain backward compatibility for existing functionality

- [ ] Add comprehensive testing
  - [ ] Unit tests for new modules and updated command classes
  - [ ] Integration tests for file I/O scenarios
  - [ ] Test auto-detection logic for various input types
  - [ ] Test format inference and precedence rules
  - [ ] Test metadata normalization across providers
  > TEST: End-to-End File I/O
  >   Type: Integration Test
  >   Assert: Complete file I/O workflow works for all formats
  >   Command: bundle exec rspec spec/integration/

## Acceptance Criteria

- [ ] `--file` flag is removed from both query commands
- [ ] Users can specify prompt and system prompt content as either files or inline text (auto-detected)
- [ ] `--output` flag saves responses to files with automatic directory creation
- [ ] Format is automatically inferred from output file extension when `--format` not specified
- [ ] `--format` flag takes precedence over file extension when both present
- [ ] JSON output includes normalized metadata (input_tokens, output_tokens, took, provider, model, timestamp)
- [ ] Markdown output includes metadata in YAML front matter following Hugo/Jekyll conventions
- [ ] Plain text output contains only response content, with summary (metadata) printed to stdout
- [ ] Execution timing is tracked and included in all structured formats
- [ ] Token counts are normalized across providers (Gemini and LMStudio)
- [ ] Output directory is created automatically if it doesn't exist
- [ ] Summary information is printed to stdout when output is saved to file
- [ ] Help text provides clear usage examples without `--file` references
- [ ] Both `llm-gemini-query` and `llm-lmstudio-query` have identical interfaces
- [ ] All existing functionality remains accessible through new interface
- [ ] Integration tests cover all file I/O scenarios and format combinations
- [ ] All documentation is updated to reflect new interface
- [ ] All tests pass: `bin/test`

## Out of Scope

- Streaming output to files
- Binary file formats
- Template system for prompts
- Interactive mode enhancements
- Cost tracking implementation (covered in task 40)
- Migration guide (not shipped to production yet)

## References & Risks

- Current implementation: `exe/llm-gemini-query`, `exe/llm-lmstudio-query`
- Related commands: `exe/llm-models` (unified model listing from task 37)
- CLI patterns: Follow ExecutableWrapper molecule pattern established in recent refactoring
- Risk: Auto-detection logic may be ambiguous for edge cases - provide clear error messages
- File path handling must work cross-platform (Windows, macOS, Linux)
- Metadata normalization must handle provider API changes gracefully
- Documentation scan targets: `docs/**/*.md`, `*.md` in project root
