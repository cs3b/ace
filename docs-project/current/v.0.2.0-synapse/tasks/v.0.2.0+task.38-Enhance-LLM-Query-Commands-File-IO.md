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
dependencies:
  - v.0.2.0+task.37
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
tree -L 1 exe | grep query

├── llm-gemini-query
├── llm-lmstudio-query
```

## Scope of Work

- Redesign command-line interface for better file I/O handling
- Add support for reading prompts and system prompts from files
- Implement multiple output formats (JSON, Markdown, Plain text)
- Add automatic format inference from file extensions
- Include metadata in structured formats (JSON, Markdown)
- Remove confusing `--file` flag in favor of explicit options

## Deliverables / Manifest

- [ ] Update `exe/llm-gemini-query` with new CLI interface
- [ ] Update `exe/llm-lmstudio-query` with new CLI interface
- [ ] Create shared file I/O module for consistency
- [ ] Create format handlers for JSON, Markdown, and Plain text
- [ ] Update command documentation and help text
- [ ] Add integration tests for file I/O scenarios

## Phases

1. **Design Phase**: Design new CLI interface and file handling architecture
2. **Shared Module Phase**: Create reusable file I/O and formatting modules
3. **Implementation Phase**: Update both query commands with new functionality
4. **Format Support Phase**: Implement all output format handlers
5. **Testing Phase**: Add comprehensive integration tests
6. **Documentation Phase**: Update all relevant documentation

## Implementation Plan

### Planning Steps
* [ ] Design new CLI interface that's intuitive and consistent
  ```bash
  # Example new interface:
  llm-gemini-query --prompt path/to/prompt.md --system path/to/system.md --output path/to/output.json --format json
  llm-gemini-query "inline prompt" --output result.md  # infers markdown from extension
  ```
* [ ] Plan metadata structure for JSON and Markdown formats
* [ ] Design shared module architecture for reuse across providers
* [ ] Determine format inference rules and precedence

### Execution Steps
- [ ] Create shared file I/O module
  - [ ] Implement file reading utilities
  - [ ] Implement file writing utilities with directory creation
  - [ ] Add format inference from file extensions
- [ ] Create format handler modules
  - [ ] JSON format handler with metadata
  - [ ] Markdown format handler with YAML front matter
  - [ ] Plain text format handler (content only)
- [ ] Update CLI argument parsing
  - [ ] Replace `--file` flag with `--prompt` for file path
  - [ ] Add `--system` flag for system prompt file path
  - [ ] Add `--output` flag for output file path
  - [ ] Add `--format` flag with auto-inference fallback
  - [ ] Make first positional argument optional (inline prompt)
  > TEST: CLI Argument Parsing
  >   Type: Unit Test
  >   Assert: New argument structure parses correctly
  >   Command: bin/test --run-cli-parser-tests
- [ ] Implement file-based prompt handling
  - [ ] Read prompt from file when `--prompt` specified
  - [ ] Read system prompt from file when `--system` specified
  - [ ] Support both absolute and relative paths
- [ ] Implement output file handling
  - [ ] Create output directory if it doesn't exist
  - [ ] Write output in specified format
  - [ ] Print summary to stdout when writing to file
  > TEST: File Output Creation
  >   Type: Integration Test
  >   Assert: Output files are created with correct format
  >   Command: bin/test --verify-output-formats
- [ ] Add format-specific features
  - [ ] JSON: Include metadata (model, tokens, cost, timestamp)
  - [ ] Markdown: Add YAML front matter with metadata
  - [ ] Plain text: Save only the response content
- [ ] Update help text and documentation
  - [ ] Clear examples in `--help` output
  - [ ] Update command documentation
- [ ] Apply changes to both commands
  - [ ] Update `llm-gemini-query`
  - [ ] Update `llm-lmstudio-query`
  - [ ] Ensure consistent behavior across providers

## Acceptance Criteria

- [ ] `--file` flag is removed in favor of explicit `--prompt` flag
- [ ] Users can specify prompt, system prompt, and output as file paths
- [ ] Format is automatically inferred from output file extension when `--format` not specified
- [ ] JSON output includes complete metadata (model, tokens, cost when available, timestamp)
- [ ] Markdown output includes metadata in YAML front matter
- [ ] Plain text output contains only the response content
- [ ] Output directory is created automatically if it doesn't exist
- [ ] Summary information is printed to stdout when output is saved to file
- [ ] Help text provides clear usage examples
- [ ] Both `llm-gemini-query` and `llm-lmstudio-query` have identical interfaces
- [ ] All existing functionality remains accessible
- [ ] Integration tests cover all file I/O scenarios

## Out of Scope

- Streaming output to files
- Binary file formats
- Template system for prompts
- Interactive mode enhancements
- Cost tracking implementation (covered in separate task)

## References & Risks

- Current implementation: `exe/llm-gemini-query`, `exe/llm-lmstudio-query`
- Risk: Breaking changes for existing scripts using `--file` flag - provide migration guide
- Consider using Ruby's built-in JSON and YAML libraries
- Markdown front matter format should follow Jekyll/Hugo conventions
- File path handling must work cross-platform (Windows, macOS, Linux)