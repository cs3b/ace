---
id: v.0.2.0+task.38
title: Enhance LLM Query Commands File I/O and Format Handling
status: done
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

* [x] Design new CLI interface with explicit file handling
  ```bash
  # New interface examples:
  llm-gemini-query path/to/prompt.md --system path/to/system.md --output path/to/output.json --format json
  llm-gemini-query "inline prompt" --output result.md  # infers markdown from extension
  llm-gemini-query path/to/prompt.txt --system "inline system prompt" --output summary.txt
  ```

* [x] Design auto-format detection logic
  - File path detection: Check if argument is a valid file path to determine file vs inline content
  - Format precedence: `--format` flag takes precedence over file extension inference
  - Support both file and inline content for `--prompt` and `--system` flags

* [x] Design metadata normalization structure
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

* [x] Plan format handlers architecture
  - JSON: Full metadata with normalized token counts
  - Markdown: YAML front matter + content
  - Plain text: Content only, metadata in summary when writing to file

* [x] Identify current `--file` flag cleanup areas
  - Remove `--file` option from both command classes
  - Update `PromptProcessor.process` method signature
  - Remove `from_file` parameter usage
  - Update related tests

### Execution Steps

- [x] Create shared file I/O module (`Molecules::FileIOHandler`)
  - [x] Implement file reading utilities with path validation
  - [x] Implement file writing utilities with directory creation
  - [x] Add format inference from file extensions
  - [x] Add path detection logic (file vs inline content)
  > TEST: File Path Detection
  >   Type: Unit Test
  >   Assert: Correctly identifies file paths vs inline content
  >   Command: bundle exec rspec spec/coding_agent_tools/molecules/file_io_handler_spec.rb

- [x] Create metadata normalization module (`Molecules::MetadataNormalizer`)
  - [x] Implement provider-specific token mapping
    - Gemini: `promptTokenCount` → `input_tokens`, `candidatesTokenCount` → `output_tokens`
    - LMStudio: `prompt_tokens` → `input_tokens`, `completion_tokens` → `output_tokens`
  - [x] Add execution timing tracking
  - [x] Add common metadata fields (provider, model, timestamp)

- [x] Create format handler modules
  - [x] JSON format handler with normalized metadata
  - [x] Markdown format handler with YAML front matter
  - [x] Plain text format handler (content only)
  - [x] Add summary generation for file output scenarios

- [x] Remove current `--file` flag implementation
  - [x] Update CLI argument parsing in both query commands
  - [x] Remove `--file` option definitions
  - [x] Update `process_prompt` methods to use auto-detection
  - [x] Update help text and examples
  > TEST: CLI Argument Parsing
  >   Type: Unit Test
  >   Assert: New argument structure parses correctly, old --file flag removed
  >   Command: bundle exec rspec spec/coding_agent_tools/cli/commands/llm/query_spec.rb spec/coding_agent_tools/cli/commands/lms/query_spec.rb

- [x] Implement new CLI interface
  - [x] Replace `--file` with auto-detection logic
  - [x] Add `--system` file support (extends existing inline support)
  - [x] Add `--output` flag for output file path
  - [x] Add `--format` flag with auto-inference fallback
  - [x] Make first positional argument support both inline and file content

- [x] Implement file-based content handling
  - [x] Auto-detect file vs inline content for prompt argument
  - [x] Auto-detect file vs inline content for `--system` argument
  - [x] Support both absolute and relative paths
  - [x] Handle file reading errors gracefully

- [x] Implement output file handling
  - [x] Create output directory if it doesn't exist
  - [x] Write output in specified or inferred format
  - [x] Print execution summary to stdout when writing to file
  - [x] Handle file writing errors gracefully
  > TEST: File Output Creation
  >   Type: Integration Test
  >   Assert: Output files created with correct format and metadata
  >   Command: bundle exec rspec spec/integration/llm_file_io_integration_spec.rb

- [x] Add format-specific features
  - [x] JSON: Include normalized metadata (input_tokens, output_tokens, took, etc.)
  - [x] Markdown: Add YAML front matter with metadata
  - [x] Plain text: Save only response content, show summary in stdout
  - [x] Add execution timing to all formats

- [x] Update help text and documentation
  - [x] Clear examples in `--help` output for both commands
  - [x] Update command documentation in `docs/llm-integration/`
  - [x] Scan and update references in `docs/**/*.md` and root `*.md` files
  - [x] Remove `--file` flag references from documentation

- [x] Apply changes consistently
  - [x] Update `llm-gemini-query` command
  - [x] Update `llm-lmstudio-query` command
  - [x] Ensure identical interface behavior across providers
  - [x] Maintain backward compatibility for existing functionality

- [x] Add comprehensive testing
  - [x] Unit tests for new modules and updated command classes
  - [x] Integration tests for file I/O scenarios with VCR
  - [x] Test auto-detection logic for various input types
  - [x] Test format inference and precedence rules
  - [x] Test metadata normalization across providers
  > TEST: End-to-End File I/O
  >   Type: Integration Test
  >   Assert: Complete file I/O workflow works for all formats
  >   Command: bundle exec rspec spec/integration/

## Acceptance Criteria

- [x] `--file` flag is removed from both query commands
- [x] Users can specify prompt and system prompt content as either files or inline text (auto-detected)
- [x] `--output` flag saves responses to files with automatic directory creation
- [x] Format is automatically inferred from output file extension when `--format` not specified
- [x] `--format` flag takes precedence over file extension when both present
- [x] JSON output includes normalized metadata (input_tokens, output_tokens, took, provider, model, timestamp)
- [x] Markdown output includes metadata in YAML front matter following Hugo/Jekyll conventions
- [x] Plain text output contains only response content, with summary (metadata) printed to stdout
- [x] Execution timing is tracked and included in all structured formats
- [x] Token counts are normalized across providers (Gemini and LMStudio)
- [x] Output directory is created automatically if it doesn't exist
- [x] Summary information is printed to stdout when output is saved to file
- [x] Help text provides clear usage examples without `--file` references
- [x] Both `llm-gemini-query` and `llm-lmstudio-query` have identical interfaces
- [x] All existing functionality remains accessible through new interface
- [x] Integration tests cover all file I/O scenarios and format combinations
- [x] All documentation is updated to reflect new interface
- [x] All tests pass: `bin/test`

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
