---
id: v.0.4.0+task.1
status: done
priority: high
estimate: 8h
dependencies: []
---

# Create ideas-manager Tool for Idea Capture

## Objective

Create a new Ruby gem executable `ideas-manager` that captures raw ideas in the project context, enhancing them with relevant questions and storing them in the
appropriate release ideas folder. This tool will be the entry point for the specification cycle, handling vague, unstructured input that may or may not become
formal tasks.

## What: Behavioral Specification

### User Experience

* **Command**: `capture-it "my raw idea text"`
* **Options**:
  * `--clipboard` to read from clipboard
  * `--file PATH` to read from file(s)
  * `--model` (default: gflash, can be overridden)
  * `--debug` to show detailed error information and processing flow
  * `--big-user-input-allowed` to allow inputs over 1000 words
* **Output**: Enhanced idea file with timestamp prefix in the appropriate ideas/ directory

### Expected Behavior

1.  Accept raw idea input from various sources (text, clipboard, files)
2.  Analyze idea in project context (architecture, existing features)
3.  Generate contextual questions that need answering for specification
4.  Create timestamped idea file with enhanced content
5.  Return path to created idea file

### Interface Contract

```bash
# Basic usage
capture-it "Add dark mode support"
# => Created: dev-taskflow/backlog/ideas/20250130-1430-dark-mode-support.md

# From clipboard
capture-it --clipboard
# => Created: dev-taskflow/backlog/ideas/20250130-1432-clipboard-idea.md
```

## How: Implementation Plan

### Planning Steps

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Audit current ideas/ directory structure across releases
  > TEST: Directory Structure Check Type: Pre-condition Check Assert: Ideas directories exist or creation logic is defined Command: find dev-taskflow -name
  > "ideas" -type d

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Research existing tool patterns in dev-tools for ATOM
  architecture consistency
  > TEST: Pattern Analysis Check Type: Research Validation Assert: CLI tool patterns and LLM integration patterns are documented Command: ls dev-tools/exe/ \|
  > wc -l && ls dev-tools/lib/coding\_agent\_tools/organisms/ \| wc -l

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Design idea enhancement prompt for LLM integration with project
  context
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Define idea.template.md format specification with required
  fields
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Implement nav-path capture-idea-new command to generate three
  paths with directories:
  > TEST: Nav-Path Integration Check Type: Path Generation Validation Assert: nav-path returns temp input, temp system prompt, and final output paths with
  > directories created Command: nav-path capture-idea-new --context "test idea for validation"

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Plan file naming and storage strategy with timestamp prefixes
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Define question generation logic based on project architecture
  and goals

### Execution Steps

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Create ideas-manager executable in dev-tools/exe/
  > TEST: Executable Creation Check Type: File Creation Validation Assert: Executable is created with proper permissions and CLI structure Command: test -x
  > dev-tools/exe/ideas-manager && ideas-manager --help

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Implement IdeaCapture organism in
  dev-tools/lib/coding\_agent\_tools/organisms/
  > TEST: Organism Unit Test Type: Unit Test Validation Assert: IdeaCapture class loads and has required methods Command: cd dev-tools && bundle exec rspec
  > spec/organisms/idea\_capture\_spec.rb

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Add clipboard reading molecule if not exists
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Extend nav-path with capture-idea-new subcommand to return
  three paths with directory creation:
  * ./tmp/\{timestamp}-\{slug}.md (temp input file)
  * ./tmp/\{timestamp}-\{slug}.system.prompt.md (temp system prompt)
  * dev-taskflow/backlog/ideas/\{timestamp}-\{slug}.md (final output path)
```xml
> TEST: Path Generation and Directory Creation Type: Integration Validation Assert: All three paths returned and directories created from project root
> Command: nav-path capture-idea-new --context "example idea" && test -d ./tmp && test -d dev-taskflow/backlog/ideas
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Create idea enhancement prompt templates (system.prompt.md and
  idea.template.md)
  > TEST: Template Creation Check Type: Template Validation Assert: Templates are created with proper format and embedded context Command: test -f
  > dev-handbook/templates/idea-manager/system.prompt.md && test -f dev-handbook/templates/idea-manager/idea.template.md

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Implement dynamic context loading for all docs/\*.md files
  > TEST: Context Loading Unit Test Type: Unit Test Validation Assert: Context loading molecule discovers and reads all docs/\*.md files Command: cd dev-tools
  > && bundle exec rspec spec/molecules/context\_loader\_spec.rb

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Implement timestamped file creation logic with proper error
  handling
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Add validation for release parameter and directory creation
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Implement LLM integration with retry logic and fallback
  handling
  > TEST: LLM Integration Unit Test Type: Unit Test Validation Assert: LLM client handles retries and fallbacks correctly Command: cd dev-tools && bundle exec
  > rspec spec/molecules/llm\_client\_spec.rb

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Implement error handling with degraded functionality guarantees
  > TEST: Error Handling Unit Test Type: Unit Test Validation Assert: Error handling preserves minimum functionality (save raw idea) Command: cd dev-tools &&
  > bundle exec rspec spec/organisms/idea\_capture\_spec.rb --tag error\_handling

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />**WRITE ACTUAL RSPEC TESTS** - Create comprehensive unit tests implementing all edge cases above
  > TEST: Unit Test Suite Type: Test Coverage Validation Assert: All 6 test files exist AND all tests pass with 90%+ coverage Command: cd dev-tools && bundle exec rspec spec/ --format documentation && bundle exec rspec --require simplecov
  > **CRITICAL**: Must write actual RSpec test files with comprehensive edge case coverage per specification above

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />**WRITE ACTUAL RSPEC TESTS** - Create integration tests implementing end-to-end workflow testing  
  > TEST: Integration Test Suite Type: End-to-End Validation Assert: Integration test file exists AND tests pass with real project data and proper cleanup Command: cd dev-tools && bundle exec rspec spec/integration/ideas\_manager\_integration\_spec.rb --format documentation
  > **CRITICAL**: Must write actual RSpec test file with comprehensive end-to-end testing per specification above

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Update dev-tools documentation and tools.md reference

## Scope of Work

### Deliverables

#### Create

* dev-tools/exe/ideas-manager
* dev-tools/lib/coding\_agent\_tools/organisms/idea\_capture.rb
* dev-tools/lib/coding\_agent\_tools/molecules/idea\_enhancer.rb
* dev-tools/lib/coding\_agent\_tools/molecules/context\_loader.rb
* dev-tools/lib/coding\_agent\_tools/molecules/llm\_client.rb
* dev-handbook/templates/idea-manager/system.prompt.md (LLM system prompt with project context)
* dev-handbook/templates/idea-manager/idea.template.md (structured idea format template)

**Unit Tests (MUST BE WRITTEN):**

* dev-tools/spec/organisms/idea\_capture\_spec.rb
* dev-tools/spec/molecules/context\_loader\_spec.rb
* dev-tools/spec/molecules/llm\_client\_spec.rb
* dev-tools/spec/molecules/idea\_enhancer\_spec.rb
* dev-tools/spec/cli/ideas\_manager\_spec.rb

**Integration Tests (MUST BE WRITTEN):**

* dev-tools/spec/integration/ideas\_manager\_integration\_spec.rb

**IMPORTANT**: These test files do not currently exist and must be created with actual RSpec test implementations before task can be marked complete.

## Comprehensive Test Edge Cases Specification

### 1. IdeaCapture Organism Tests (`idea_capture_spec.rb`)

**Happy Path Test Cases:**
- ✅ Basic idea capture with valid input (10-100 words)
- ✅ Large input with `--big-user-input-allowed` flag (>1000 words)
- ✅ Successful LLM enhancement and file creation
- ✅ Git commit integration when `commit_after_capture: true`
- ✅ Debug mode output validation

**Input Validation Edge Cases:**
- ❌ `nil` input → "Idea text cannot be nil" 
- ❌ Empty string input → "Idea text cannot be empty"
- ❌ Whitespace-only input → "Idea text cannot be empty"
- ❌ Input under 5 characters → "Idea text must be at least 5 characters"
- ✅ Input exactly at 5 characters minimum
- ✅ Input exactly at size limits (1000 words, 7000 chars)
- ❌ Input over size limits without flag → "Input too large: X KB, Y words. Use --big-user-input-allowed to proceed"
- ✅ Input over size limits with `big_user_input_allowed: true`
- ✅ Unicode characters and emoji handling
- ✅ Very long single words (no spaces)
- ✅ Input with only newlines/tabs (should be stripped)

**Path Generation Edge Cases:**
- ❌ Path generation failure → "Path generation failed" error
- ✅ Invalid characters in generated slugs (sanitization)
- ✅ Very long idea text affecting path length (truncation)
- ✅ Concurrent path generation (race conditions)
- ❌ Directory creation permission failures → file system error

**File System Edge Cases:**
- ❌ Read-only directories → "Permission denied" error  
- ❌ Disk space exhaustion → "No space left on device" error
- ❌ File permission errors → proper error handling
- ✅ Concurrent file access (atomic operations)
- ❌ Network drive failures → fallback behavior
- ✅ Special characters in paths (encoding)

**LLM Integration Edge Cases:**
- ❌ All retry attempts failing → save raw idea fallback
- ✅ Partial LLM responses → validation and retry
- ❌ LLM timeout scenarios → retry logic
- ❌ Invalid model names → error handling
- ❌ API rate limiting → exponential backoff
- ❌ Network connectivity issues → fallback behavior
- ❌ Empty LLM responses → validation error
- ❌ Malformed LLM output → fallback to raw idea

**Git Commit Edge Cases:**
- ❌ Git not available in PATH → error message
- ❌ Git repository not initialized → error handling
- ❌ Dirty working directory → commit handling
- ❌ Git hooks failing → error propagation
- ❌ Permission errors with git files → proper error messages
- ✅ Test environment detection (skip commits)

**Context Loading Integration:**
- ✅ Successful context loading → enhanced prompts
- ❌ Context loading failures → degraded functionality
- ✅ Mixed success/failure context loading → partial context usage
- ❌ No docs directory → error handling with fallback

### 2. ContextLoader Molecule Tests (`context_loader_spec.rb`)

**Happy Path Test Cases:**
- ✅ Load all docs/*.md files successfully 
- ✅ Generate proper XML embedded format with `<context><document path="...">content</document></context>`
- ✅ Handle nested subdirectories (docs/subdir/*.md)
- ✅ Proper relative path generation

**File Discovery Edge Cases:**
- ❌ Empty docs directory → "No documentation files found"
- ❌ Missing docs directory → "Docs directory not found: /path/to/docs"
- ✅ Symlinks in docs directory (follow or ignore)
- ✅ Hidden files (.hidden.md) → should be included
- ❌ Files with no extension → skip silently  
- ❌ Non-UTF8 encoded files → encoding error handling
- ❌ Binary files with .md extension → read error handling

**File Reading Edge Cases:**
- ❌ Permission denied on specific files → add to failed_files array
- ❌ Files locked by other processes → retry or skip
- ❌ Files changing during read → handle gracefully
- ✅ Extremely large documentation files (>1MB)
- ✅ Files with BOM markers → proper encoding handling
- ✅ Files with mixed line endings (\\r\\n, \\n, \\r)
- ❌ Corrupted file content → skip with error log

**XML Generation Edge Cases:**
- ✅ Files with XML special characters (`<>&"'`) → proper escaping
- ✅ Files with CDATA sections → preserve content
- ✅ Files with encoding issues → fallback handling
- ✅ Empty files → include with empty content
- ✅ Files with only whitespace → preserve whitespace

**Error Aggregation Tests:**
- ✅ Partial success (some files fail) → return success with warnings
- ✅ Complete failure (all files fail) → return failure
- ✅ Mixed file types → process .md files only
- ✅ Error reporting → detailed failed_files information

### 3. LLMClient Molecule Tests (`llm_client_spec.rb`)

**Happy Path Test Cases:**
- ✅ Successful LLM query execution → LLMResult.success? == true
- ✅ Proper retry logic with eventual success → retry_count tracking
- ✅ Different model providers → model parameter handling
- ✅ Debug mode logging → debug output validation

**Retry Logic Edge Cases:**
- ❌ All retries failing → LLMResult.success? == false, max retry_count
- ✅ Intermittent failures → fail, succeed pattern handling
- ✅ Exponential backoff timing → 1s, 3s, 9s delays
- ✅ Retry on different error types → network, API, timeout errors
- ✅ Success on final retry attempt → retry_count == MAX_RETRIES

**Command Execution Edge Cases:**
- ❌ `llm-query` executable not found → "Command not found" error
- ❌ Invalid command line arguments → argument validation
- ❌ System command timeout → timeout error handling
- ❌ Process termination/signals → SIGTERM/SIGKILL handling
- ❌ Environment variable issues → ENV validation
- ❌ PATH resolution problems → executable path validation

**Input/Output Edge Cases:**
- ❌ Missing input files → "Input file not found" error
- ❌ Corrupt system prompt files → file validation
- ❌ Output directory doesn't exist → directory creation
- ❌ Output file permission errors → permission error handling
- ✅ Concurrent access to same files → file locking
- ✅ Very large input/output files → streaming/chunking

**Path Validation Tests:**
- ❌ Nil paths → "Path cannot be nil" error
- ❌ Empty string paths → "Path cannot be empty" error
- ❌ Non-existent input paths → "Input file does not exist" error
- ❌ Directory as file path → "Path is a directory" error
- ✅ Relative vs absolute path handling

### 4. IdeaEnhancer Molecule Tests (`idea_enhancer_spec.rb`)

**Happy Path Test Cases:**
- ✅ Extract title from various input formats
- ✅ Generate relevant questions based on content keywords
- ✅ Validate content successfully → {valid: true, content: cleaned}
- ✅ Handle project context in question generation

**Title Extraction Edge Cases:**
- ✅ Single word inputs → return single word
- ✅ Very long first lines (>80 chars) → truncate at word boundary + "..."
- ✅ Inputs starting with prefixes → remove "idea:", "thought:", "suggestion:"
- ✅ Inputs with only punctuation → clean punctuation-only content
- ✅ Inputs with Unicode characters → preserve Unicode
- ✅ Inputs with HTML/Markdown → strip formatting
- ✅ Multiple sentences in first line → extract first sentence only

**Question Generation Edge Cases:**
- ✅ Inputs with no recognizable keywords → default validation questions
- ✅ Inputs mentioning multiple categories → combine relevant questions
- ✅ Very short inputs → basic validation questions only
- ✅ Technical jargon detection → technical-specific questions
- ✅ Feature/improvement keyword detection → category-specific questions
- ✅ Tool/command keyword detection → CLI/integration questions
- ✅ Question count limiting → maximum 6 questions

**Content Validation Edge Cases:**
- ❌ Nil content → {valid: false, error: "Idea content cannot be nil"}
- ❌ Empty string → {valid: false, error: "Idea content cannot be empty"}  
- ❌ Whitespace only → {valid: false, error: "Idea content cannot be empty"}
- ❌ Under 5 characters → {valid: false, error: "Idea content too short"}
- ✅ Exactly 5 characters → {valid: true, content: cleaned}
- ✅ Mixed whitespace types → proper stripping
- ✅ Control characters → sanitization handling

### 5. CLI Command Tests (`ideas_manager_spec.rb`)

**Happy Path Test Cases:**
- ✅ Basic command execution → `capture-it "test idea"`
- ✅ All option combinations → test matrix of all flags
- ✅ Help command → `ideas-manager --help`
- ✅ Version command → `ideas-manager --version`

**CLI Option Edge Cases:**
- ❌ Conflicting options → error for `--clipboard` and `--file` together
- ❌ Invalid file paths → "File not found" error for `--file`
- ❌ Non-existent model names → model validation error
- ✅ Boolean flag variations → `--debug`, `--no-debug`
- ❌ Missing required dependencies → dependency validation

**Input Source Edge Cases:**
- ❌ Clipboard empty → "Clipboard is empty" error
- ❌ Clipboard unavailable → fallback to prompt for input
- ❌ File doesn't exist → "File not found: /path/to/file"
- ❌ File is binary → "File appears to be binary"
- ❌ File is too large → size limit validation
- ❌ Permission denied reading file → permission error
- ❌ Network file access → network error handling

**Output Handling Edge Cases:**
- ✅ STDOUT redirection → proper output formatting
- ✅ STDERR separation → errors to STDERR only
- ✅ Exit code validation → 0 for success, 1 for errors
- ✅ Signal handling → graceful SIGINT/SIGTERM handling
- ✅ Terminal width considerations → output formatting

**Error Message Format Tests:**
- ✅ Standard error format → "Error: message"
- ✅ Debug mode errors → full stack traces
- ✅ User-friendly messages → avoid technical jargon
- ✅ Actionable error suggestions → "Use --flag to proceed"

### 6. Integration Tests (`ideas_manager_integration_spec.rb`)

**End-to-End Workflow Tests:**
- ✅ Complete idea capture workflow → input → enhancement → output file
- ✅ Multiple ideas in sequence → no interference between captures
- ✅ Concurrent idea captures → race condition testing
- ✅ Full project context loading → real docs/* files integration
- ✅ Real LLM integration → if API credentials available (or mock)

**Cross-Component Integration:**
- ✅ CLI → Organism → Molecules interaction chain
- ✅ Error propagation across layers → proper error bubbling
- ✅ Debug logging across components → consistent debug output
- ✅ Path resolver → Context loader → LLM client chain

**Real Project Data Tests:**
- ✅ Using actual project docs/* files → real context loading
- ✅ Testing with real project structure → file system integration
- ✅ Cleanup of generated test files → proper test isolation
- ✅ Integration with actual git repository → real git operations

**Performance Edge Cases:**
- ✅ Large project contexts → many docs files performance
- ✅ High-frequency idea captures → stress testing
- ✅ Memory usage patterns → memory leak detection
- ✅ File system stress testing → many concurrent operations

**Test Environment Setup:**
- ✅ Mock LLM responses for consistent testing
- ✅ Temporary directory setup and cleanup
- ✅ Git repository isolation for commit tests
- ✅ Environment variable management
- ✅ Test data fixtures and factories

## Test Implementation Requirements

**RSpec Test Structure:**
- All tests use `describe` and `context` blocks for organization
- Use `let` and `let!` for test data setup
- Include `before` and `after` hooks for setup/cleanup
- Use shared examples for common behavior testing
- Include proper test isolation (no state leaking between tests)

**Test Coverage Requirements:**
- **Unit Tests**: 90%+ line coverage for each component
- **Integration Tests**: End-to-end workflow coverage
- **Edge Cases**: All error conditions must be tested
- **Boundary Conditions**: Test limits and thresholds
- **Error Scenarios**: Every error path must have test coverage

**Test Data Management:**
- **Fixtures**: Use fixtures for complex test data
- **Factories**: Create test data factories for objects
- **Mocking**: Mock external dependencies (LLM APIs, file system)
- **Isolation**: Each test creates and cleans up its own data
- **Deterministic**: Tests produce consistent results

**Assertion Standards:**
- Use specific expectations (`expect().to eq()`, not `expect().to be_truthy`)
- Test both positive and negative cases
- Include error message validation
- Test return value structure and types
- Validate side effects (file creation, logging)

## Test Execution Standards

**Required Commands:**
```bash
# All tests must pass
cd dev-tools && bundle exec rspec

# Individual test files must be runnable
cd dev-tools && bundle exec rspec spec/organisms/idea_capture_spec.rb
cd dev-tools && bundle exec rspec spec/molecules/context_loader_spec.rb
cd dev-tools && bundle exec rspec spec/molecules/llm_client_spec.rb
cd dev-tools && bundle exec rspec spec/molecules/idea_enhancer_spec.rb
cd dev-tools && bundle exec rspec spec/cli/ideas_manager_spec.rb
cd dev-tools && bundle exec rspec spec/integration/ideas_manager_integration_spec.rb

# Test output format must be documentation style
cd dev-tools && bundle exec rspec --format documentation

# Coverage reporting
cd dev-tools && bundle exec rspec --require simplecov
```

**Performance Requirements:**
- Unit tests: < 5 seconds total
- Integration tests: < 30 seconds total  
- Individual test cases: < 1 second each
- Memory usage: < 100MB per test suite

**Test Environment Detection:**
Tests must properly detect test environments and:
- Skip git commits in test runs
- Use temporary directories for file operations
- Mock external API calls (LLM services)
- Clean up all created files and directories
- Not interfere with actual project files

#### Modify

* dev-tools/lib/coding\_agent\_tools.rb (register new components)
* dev-tools/lib/coding\_agent\_tools/cli/commands/nav/path.rb (add capture-idea-new subcommand)
* docs/tools.md (add ideas-manager documentation)

## Acceptance Criteria

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Tool captures ideas from text, clipboard, and files
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Ideas are enhanced with project context
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Relevant questions are generated for each idea
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Files are created with proper timestamp naming
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Release targeting works correctly
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />**All RSpec tests exist and pass with comprehensive edge case coverage** (cannot be marked complete until all 6 test files are written and pass per specification above)
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Documentation is complete

## Template Specifications

<documents>
<template path="dev-handbook/templates/idea-manager/idea.template.md"># {title}

## Intention

{clear_one_sentence_purpose}

## Problem It Solves

**Observed Issues:**
- {specific_issue_1}
- {specific_issue_2} 
- {specific_issue_3}

**Impact:**
- {consequence_1}
- {consequence_2}
- {consequence_3}

## Key Patterns from Reflections

{patterns_extracted_from_project_context}

## Solution Direction

1. **{approach_1}**: {description}
2. **{approach_2}**: {description}
3. **{approach_3}**: {description}

## Critical Questions

**Before proceeding, we need to answer:**
1. {validation_question_1}
2. {validation_question_2}
3. {validation_question_3}

**Open Questions:**
- {uncertainty_1}
- {uncertainty_2}
- {uncertainty_3}

## Assumptions to Validate

**We assume that:**
- {assumption_1} - *Needs validation*
- {assumption_2} - *Needs validation*
- {assumption_3} - *Needs validation*

## Expected Benefits

- {benefit_1}
- {benefit_2}
- {benefit_3}

## Big Unknowns

**Technical Unknowns:**
- {technical_uncertainty_1}
- {technical_uncertainty_2}

**User/Market Unknowns:**
- {user_uncertainty_1}
- {user_uncertainty_2}

**Implementation Unknowns:**
- {implementation_uncertainty_1}
- {implementation_uncertainty_2}
</template>
</documents>

### system.prompt.md Structure

* LLM instructions for idea enhancement
* Embedded idea.template.md format
* Dynamic project context from all docs/\*.md files
* Output formatting constraints

## Context Loading Specification

### Files to Include

**Dynamic Loading**: Load all `docs/*.md` files fresh for each command execution

* `docs/what-do-we-build.md` (project vision)
* `docs/architecture.md` (system design)
* `docs/blueprint.md` (project structure)
* All other `docs/*.md` files found at runtime

### Size Limits and Input Validation

* **No Context Size Limit**: gflash supports 200K+ tokens (up to 1M), docs/\*.md files are acceptable
* **User Input Limit**: 1000 words maximum unless `--big-user-input-allowed` flag provided
* **Size Reporting**: Show input size in KB and words when rejecting large inputs
* **Example**: `"Input too large: 15.2 KB, 2,431 words. Use --big-user-input-allowed to proceed"`

### Context Embedding Format

**Use embedded documents format (similar to code-review context):**

<context>
    <document path="docs/what-do-we-build.md">
        [full file content]
    </document>
    <document path="docs/architecture.md">
        [full file content]
    </document>
    <document path="docs/blueprint.md">
        [full file content]
    </document>
    <!-- All other docs/*.md files -->
</context>
```

### Loading Strategy

* **Dynamic Loading**: Fresh context load for each command (no caching)
* **Runtime Discovery**: Scan docs/ directory for all .md files at execution time
* **File Reading**: Read each file completely, embed in system prompt
* **Error Tolerance**: Continue with available files if some fail to load

### Fallback Behavior

**Minimum Guarantee**: Always save raw user input to ideas folder, regardless of context loading issues

* Show context loading errors to user
* Continue with whatever context successfully loaded
* Use embedded backup template if all context loading fails
* Save raw idea as absolute minimum functionality

## Example Workflow

```bash
capture-it "every task definition should have an example section"
```

### 1. **Generate Slug and Get Paths**

```bash
# Generate slug using LLM
llm-query gflash "every task definition should have an example section" --system "return only 3 word slug for the context (lowercase linked by hyphens)"
# => task-example-section

# Get three paths with directory creation
nav-path capture-idea-new --context "every task definition should have an example section"
```

**Returns:**

```bash
input: tmp/20250730-1430-task-example-section.md
system: tmp/20250730-1430-task-example-section.system.prompt.md  
output: dev-taskflow/backlog/ideas/20250730-1430-task-example-section.md

### 2. **Save Raw Idea**

Creates temp input file with raw idea text at returned input path.

### 3. **Generate System Prompt**

Creates temp system prompt with:

* Enhancement instructions using embedded template
* Project context from docs/\*.md files
* LLM formatting constraints

### 4. **Call LLM Enhancement**

llm-query gflash tmp/20250730-1430-task-example-section.md \
--system-prompt tmp/20250730-1430-task-example-section.system.prompt.md \
--output dev-taskflow/backlog/ideas/20250730-1430-task-example-section.md
```

### 5. **Return Output Path**

```bash
# => Created: dev-taskflow/backlog/ideas/20250730-1430-task-example-section.md
```

## Error Handling Strategy

### Core Principle: Degraded Functionality Over Complete Failure

**Always save user input to ideas folder, even if enhancement fails**

### Failure Scenarios & Responses

#### 1. LLM API Failures

* **Retry Logic**: 3 attempts with exponential backoff (1s, 3s, 9s)
* **Fallback**: Save raw idea without enhancement if all retries fail
* **User Feedback**:
  * Default: `"Enhancement failed, saved raw idea: [path]"`
  * Debug: Full API error details and retry attempts

#### 2. Slug Generation Failures

* **Input Limit**: Send max 100 first words to LLM for slug generation
* **Fallback**: Use first 3 words from input, lowercase with hyphens
* **nav-path Responsibility**: If nav-path fails, use basic timestamp naming

#### 3. File System Failures

* **Pre-flight Checks**: Validate write permissions before processing
* **Atomic Operations**: Use temp files then move to final location
* **Cleanup**: Remove partial files on failure
* **User Feedback**:
  * Default: `"File creation failed, check permissions"`
  * Debug: Full path and permission details

#### 4. Input Processing Failures

* **Validation**: Minimum 5 characters required
* **Large Input Check**: Reject inputs over 1000 words unless `--big-user-input-allowed` flag provided
* **File Size Limit**: Max 10KB input files with truncation warning
* **Clipboard Fallback**: Prompt for manual input if clipboard fails
* **User Feedback**:
  * Default: `"Input too large: [X] KB, [Y] words. Use --big-user-input-allowed to proceed"`
  * Debug: Specific validation failure reason and input size details

#### 5. System Context Loading Failures

* **Template Missing**: Use embedded backup template
* **Context Files Unreadable**: Show errors, continue with available files, save raw idea as minimum
* **Dynamic Loading**: Load all docs/\*.md files fresh for each command
* **User Feedback**:
  * Default: `"Context loading issues, saved raw idea: [path]"`
  * Debug: List of failed context files, sizes, and specific error reasons

### Debug Mode Behavior

* **Flag**: `--debug` shows detailed processing flow
* **Output**: All steps, retry attempts, fallback decisions to stdout
* **Error Details**: Full stack traces and API responses
* **No Logging**: Debug info only goes to stdout, no persistent logs

### Minimum Guarantee

**Tool will always:**

1.  Save user input to `dev-taskflow/backlog/ideas/{timestamp}-{slug}.md`
2.  Use project tmp directory (`tmp/`) not system temp
3.  Provide meaningful file names even if slug generation fails
4.  Return path to created file regardless of enhancement status

## Test Validation Approach

### **⚠️ CRITICAL: ACTUAL TEST WRITING REQUIRED**   {#️-critical-actual-test-writing-required}

**This task cannot be completed until all RSpec test files are written and passing.**

**Current Status:**

* ✅ Functional implementation complete (tool works manually)
* ❌ **RSpec test files missing** (6 test files need to be written)
* ❌ **Test execution failing** (no tests exist to run)

**Required Before Task Completion:**

1.  **Write all 6 RSpec test files** with actual test implementations
2.  **Ensure all tests pass** when running `bundle exec rspec`
3.  **Verify test coverage** for all implemented components
4.  **Validate file existence** of all specified test deliverables

### Testing Strategy

**Unit Tests First, Then Integration Tests**

#### 1. Unit Test Requirements

* **Independent Tests**: Each test runs independently without dependencies
* **Component Focus**: Test individual atoms, molecules, and organisms separately
* **Fast Execution**: Unit tests should run quickly for development feedback
* **Failure Expected**: Tests should fail if commands/components don't exist yet
* **Real Data**: Tests can use real project data with proper cleanup

#### 2. Test Organization

    dev-tools/spec/
    ├── atoms/                    # Basic utility tests
    ├── molecules/                # Behavior component tests
    │   ├── context_loader_spec.rb
    │   ├── llm_client_spec.rb
    │   └── idea_enhancer_spec.rb
    ├── organisms/                # Business logic tests
    │   └── idea_capture_spec.rb
    ├── cli/                      # CLI command tests
    │   └── ideas_manager_spec.rb
    └── integration/              # End-to-end tests
        └── ideas_manager_integration_spec.rb

#### 3. Test Categories

**Unit Tests (Primary)**

* Context loading functionality
* LLM client with retry logic
* Error handling with degraded functionality
* File creation and naming logic
* Input validation and size checking

**Integration Tests (Secondary)**

* End-to-end idea capture workflow
* Real project data with cleanup
* Cross-component interaction validation
* CLI interface testing

#### 4. Test Data Management

* **Use Real Project**: Tests can operate on actual project data
* **Cleanup Required**: All tests must clean up created files/directories
* **Isolation**: Tests must not interfere with each other
* **Deterministic**: Tests should produce consistent results

#### 5. Test Command Standards

* **Assume Tool Exists**: Test commands expect components to be implemented
* **Fail Fast**: Commands should fail immediately if prerequisites missing
* **Clear Assertions**: Each test has specific, testable assertions
* **Path Independence**: Tests work from project root or dev-tools directory

## Remaining Work to Complete Task

### **CRITICAL: Missing Test Implementation**

**The following RSpec test files must be written before task completion:**

1.  **`dev-tools/spec/organisms/idea_capture_spec.rb`**
    * Test IdeaCapture organism functionality
    * Test error handling and degraded functionality
    * Test file creation and naming logic
2.  **`dev-tools/spec/molecules/context_loader_spec.rb`**
    * Test dynamic loading of all docs/\*.md files
    * Test XML embedding format generation
    * Test error handling for missing/unreadable files
3.  **`dev-tools/spec/molecules/llm_client_spec.rb`**
    * Test LLM integration with retry logic
    * Test fallback behavior on API failures
    * Test different model providers
4.  **`dev-tools/spec/molecules/idea_enhancer_spec.rb`**
    * Test idea enhancement workflow
    * Test template application
    * Test system prompt generation
5.  **`dev-tools/spec/cli/ideas_manager_spec.rb`**
    * Test CLI interface and option parsing
    * Test command execution and output
    * Test error message formatting
6.  **`dev-tools/spec/integration/ideas_manager_integration_spec.rb`**
    * Test end-to-end idea capture workflow
    * Test real project data handling with cleanup
    * Test integration between all components

### **Acceptance Criteria Update**

* **Task Status**: Pending (reopened)
* **Blocker**: Missing automated test implementation
* **Definition of Done**: All 6 test files exist AND all tests pass

## Out of Scope

* ❌ Automatic task creation from ideas
* ❌ Idea prioritization or filtering
* ❌ Integration with task-manager
* ❌ Idea status tracking

## References

* Research document: dev-taskflow/current/v.0.3.0-workflows/backlog/research/how-to-build-planning-agents-without-loosing-control.md
* Existing idea: dev-taskflow/backlog/ideas/exe-capture-it-new.md