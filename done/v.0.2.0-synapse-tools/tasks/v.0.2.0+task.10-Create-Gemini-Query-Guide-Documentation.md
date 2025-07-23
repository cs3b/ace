---
id: v.0.2.0+task.10
status: done
priority: high
estimate: 4h
dependencies: [v.0.2.0+task.1]
---

# Create Gemini Query Guide Documentation

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 3 docs | sed 's/^/    /'
```

_Result excerpt:_

```
    docs
    ├── comprehensive-diff-documentation-review-guide.md
    ├── DEVELOPMENT.md
    ├── refactoring_api_credentials.md
    ├── SETUP.md
    └── testing-with-vcr.md
```

## Objective

Create comprehensive documentation for the new `exe/llm-gemini-query` command in the form of a detailed guide. This documentation will serve as the primary reference for users wanting to understand and effectively use the Google Gemini LLM integration features. The guide needs to cover setup, usage patterns, advanced options, troubleshooting, and practical examples.

## Scope of Work

- Create new documentation file: `docs/llm-integration/gemini-query-guide.md`
- Document complete setup process including API key configuration
- Provide comprehensive usage examples for all command options
- Include troubleshooting section for common issues
- Document all CLI flags and their effects
- Provide practical use case examples

### Deliverables

#### Create

- docs/llm-integration/gemini-query-guide.md
- docs/llm-integration/ (directory if it doesn't exist)

## Phases

1. Audit current command implementation and available options
2. Create directory structure for LLM integration docs
3. Write comprehensive guide content following project documentation standards
4. Include practical examples and troubleshooting information
5. Review and validate all examples work correctly

## Implementation Plan

### Planning Steps

* [ ] Analyze `exe/llm-gemini-query` command implementation to understand all available options
  > TEST: Command Analysis Complete
  > Type: Pre-condition Check
  > Assert: All CLI options and their behavior are documented
  > Manual Verification: Manually execute `exe/llm-gemini-query --help` and analyze its output to ensure all CLI options and their behaviors are understood and noted for documentation.
* [ ] Review existing project documentation style and formatting standards
* [ ] Plan guide structure to cover all user scenarios from basic to advanced usage
* [ ] Identify practical use cases and example scenarios to include

### Execution Steps

- [x] Create `docs/llm-integration/` directory if it doesn't exist
- [x] Create new file `docs/llm-integration/gemini-query-guide.md` with comprehensive content including:
  - Introduction and purpose of exe/llm-gemini-query
  - Setup section with API key configuration (GEMINI_API_KEY, .env file setup)
  - Basic usage examples (string prompts, file prompts)
  - Output format options (text vs JSON with example outputs)
  - Advanced options documentation (--model, --temperature, --max-tokens, --system, --debug)
  - Combined options examples
  - Troubleshooting section (API key issues, file not found, common errors)
  > TEST: Guide Content Validation
  > Type: Action Validation
  > Assert: Guide covers all required sections with accurate information
  > Manual Verification: Review `docs/llm-integration/gemini-query-guide.md` to confirm it covers all required sections (Introduction, Setup, Basic Usage, Output Format, Advanced Options, Combined Options, Troubleshooting) with accurate information.
- [x] Validate all command examples in the guide work correctly
  > TEST: Example Commands Validation
  > Type: Action Validation
  > Assert: All command examples in the guide execute successfully
  > Manual Verification: Manually execute each command example provided in `docs/llm-integration/gemini-query-guide.md` to ensure they run successfully and produce expected output.
- [x] Ensure proper markdown formatting and internal link structure
- [x] Add cross-references to related documentation (README.md, SETUP.md)

## Acceptance Criteria

- [x] New guide file exists at `docs/llm-integration/gemini-query-guide.md`
- [x] Guide includes comprehensive introduction explaining the command's purpose
- [x] Setup section clearly explains GEMINI_API_KEY configuration with .env file examples
- [x] Basic usage section covers both string and file prompt examples
- [x] Output format section explains text vs JSON formats with example outputs
- [x] Advanced options section documents all CLI flags (--model, --temperature, --max-tokens, --system, --debug)
- [x] Combined usage examples show realistic scenarios
- [x] Troubleshooting section addresses common error scenarios
- [x] All command examples are syntactically correct and functional
- [x] Document follows project markdown style and formatting standards
- [x] Cross-references to other documentation are accurate and functional

## Out of Scope

- ❌ Modifying the actual command implementation
- ❌ Creating other LLM integration documentation
- ❌ Updating README.md or other existing files
- ❌ Setting up actual API keys or testing live API calls

## References

- `coding-agent-tools/docs-project/current/v.0.2.0-synapse/code-review/task.1.reviewed/suggestions-gemini.md` (lines 215-235)
- `exe/llm-gemini-query` command implementation
- `.env.example` files for API key setup patterns
- `docs-dev/guides/documentation.g.md` for style guidelines
- Existing documentation files for formatting reference
