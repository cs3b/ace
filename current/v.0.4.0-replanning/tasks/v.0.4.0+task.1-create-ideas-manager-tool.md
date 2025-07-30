---
id: v.0.4.0+task.1
status: pending
priority: high
estimate: 8h
dependencies: []
---

# Create ideas-manager Tool for Idea Capture

## Objective

Create a new Ruby gem executable `ideas-manager` that captures raw ideas in the project context, enhancing them with relevant questions and storing them in the appropriate release ideas folder. This tool will be the entry point for the specification cycle, handling vague, unstructured input that may or may not become formal tasks.

## What: Behavioral Specification

### User Experience
- **Command**: `ideas-manager capture "my raw idea text"`
- **Options**:
  - `--clipboard` to read from clipboard
  - `--file PATH` to read from file(s)
  - `--model` (default: gflash, can be overridden)
  - `--debug` to show detailed error information and processing flow
  - `--big-user-input-allowed` to allow inputs over 1000 words
- **Output**: Enhanced idea file with timestamp prefix in the appropriate ideas/ directory

### Expected Behavior
1. Accept raw idea input from various sources (text, clipboard, files)
2. Analyze idea in project context (architecture, existing features)
3. Generate contextual questions that need answering for specification
4. Create timestamped idea file with enhanced content
5. Return path to created idea file

### Interface Contract
```bash
# Basic usage
ideas-manager capture "Add dark mode support"
# => Created: dev-taskflow/backlog/ideas/20250130-1430-dark-mode-support.md

# From clipboard
ideas-manager capture --clipboard
# => Created: dev-taskflow/backlog/ideas/20250130-1432-clipboard-idea.md
```

## How: Implementation Plan

### Planning Steps
* [ ] Audit current ideas/ directory structure across releases
  > TEST: Directory Structure Check
  > Type: Pre-condition Check
  > Assert: Ideas directories exist or creation logic is defined
  > Command: find dev-taskflow -name "ideas" -type d
* [ ] Research existing tool patterns in dev-tools for ATOM architecture consistency
  > TEST: Pattern Analysis Check
  > Type: Research Validation
  > Assert: CLI tool patterns and LLM integration patterns are documented
  > Command: ls dev-tools/exe/ | wc -l && ls dev-tools/lib/coding_agent_tools/organisms/ | wc -l
* [ ] Design idea enhancement prompt for LLM integration with project context
* [ ] Define idea.template.md format specification with required fields
* [ ] Implement nav-path capture-idea-new command to generate three paths with directories:
  > TEST: Nav-Path Integration Check
  > Type: Path Generation Validation
  > Assert: nav-path returns temp input, temp system prompt, and final output paths with directories created
  > Command: nav-path capture-idea-new --context "test idea for validation"
* [ ] Plan file naming and storage strategy with timestamp prefixes
* [ ] Define question generation logic based on project architecture and goals

### Execution Steps
- [ ] Create ideas-manager executable in dev-tools/exe/
  > TEST: Executable Creation Check
  > Type: File Creation Validation
  > Assert: Executable is created with proper permissions and CLI structure
  > Command: test -x dev-tools/exe/ideas-manager && ideas-manager --help
- [ ] Implement IdeaCapture organism in dev-tools/lib/coding_agent_tools/organisms/
  > TEST: Organism Unit Test
  > Type: Unit Test Validation
  > Assert: IdeaCapture class loads and has required methods
  > Command: cd dev-tools && bundle exec rspec spec/organisms/idea_capture_spec.rb
- [ ] Add clipboard reading molecule if not exists
- [ ] Extend nav-path with capture-idea-new subcommand to return three paths with directory creation:
  - ./tmp/{timestamp}-{slug}.md (temp input file) 
  - ./tmp/{timestamp}-{slug}.system.prompt.md (temp system prompt)
  - dev-taskflow/backlog/ideas/{timestamp}-{slug}.md (final output path)
  > TEST: Path Generation and Directory Creation
  > Type: Integration Validation
  > Assert: All three paths returned and directories created from project root
  > Command: nav-path capture-idea-new --context "example idea" && test -d ./tmp && test -d dev-taskflow/backlog/ideas
- [ ] Create idea enhancement prompt templates (system.prompt.md and idea.template.md)
  > TEST: Template Creation Check
  > Type: Template Validation
  > Assert: Templates are created with proper format and embedded context
  > Command: test -f dev-handbook/templates/idea-manager/system.prompt.md && test -f dev-handbook/templates/idea-manager/idea.template.md
- [ ] Implement dynamic context loading for all docs/*.md files
  > TEST: Context Loading Unit Test
  > Type: Unit Test Validation
  > Assert: Context loading molecule discovers and reads all docs/*.md files
  > Command: cd dev-tools && bundle exec rspec spec/molecules/context_loader_spec.rb
- [ ] Implement timestamped file creation logic with proper error handling
- [ ] Add validation for release parameter and directory creation
- [ ] Implement LLM integration with retry logic and fallback handling
  > TEST: LLM Integration Unit Test
  > Type: Unit Test Validation
  > Assert: LLM client handles retries and fallbacks correctly
  > Command: cd dev-tools && bundle exec rspec spec/molecules/llm_client_spec.rb
- [ ] Implement error handling with degraded functionality guarantees
  > TEST: Error Handling Unit Test
  > Type: Unit Test Validation
  > Assert: Error handling preserves minimum functionality (save raw idea)
  > Command: cd dev-tools && bundle exec rspec spec/organisms/idea_capture_spec.rb --tag error_handling
- [ ] Create comprehensive unit tests in dev-tools/spec/
  > TEST: Unit Test Suite
  > Type: Test Coverage Validation
  > Assert: All components have unit tests with good coverage
  > Command: cd dev-tools && bundle exec rspec spec/ --format documentation
- [ ] Create integration tests for end-to-end functionality
  > TEST: Integration Test Suite
  > Type: End-to-End Validation
  > Assert: Tool works end-to-end with real project data and cleanup
  > Command: cd dev-tools && bundle exec rspec spec/integration/ideas_manager_integration_spec.rb
- [ ] Update dev-tools documentation and tools.md reference

## Scope of Work

### Deliverables

#### Create
- dev-tools/exe/ideas-manager
- dev-tools/lib/coding_agent_tools/organisms/idea_capture.rb
- dev-tools/lib/coding_agent_tools/molecules/idea_enhancer.rb
- dev-tools/lib/coding_agent_tools/molecules/context_loader.rb
- dev-tools/lib/coding_agent_tools/molecules/llm_client.rb
- dev-handbook/templates/idea-manager/system.prompt.md (LLM system prompt with project context)
- dev-handbook/templates/idea-manager/idea.template.md (structured idea format template)

**Unit Tests:**
- dev-tools/spec/organisms/idea_capture_spec.rb
- dev-tools/spec/molecules/context_loader_spec.rb
- dev-tools/spec/molecules/llm_client_spec.rb
- dev-tools/spec/molecules/idea_enhancer_spec.rb
- dev-tools/spec/cli/ideas_manager_spec.rb

**Integration Tests:**
- dev-tools/spec/integration/ideas_manager_integration_spec.rb

#### Modify
- dev-tools/lib/coding_agent_tools.rb (register new components)
- dev-tools/lib/coding_agent_tools/cli/commands/nav/path.rb (add capture-idea-new subcommand)
- docs/tools.md (add ideas-manager documentation)

## Acceptance Criteria

- [ ] Tool captures ideas from text, clipboard, and files
- [ ] Ideas are enhanced with project context
- [ ] Relevant questions are generated for each idea
- [ ] Files are created with proper timestamp naming
- [ ] Release targeting works correctly
- [ ] All tests pass
- [ ] Documentation is complete

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
- LLM instructions for idea enhancement
- Embedded idea.template.md format  
- Dynamic project context from all docs/*.md files
- Output formatting constraints

## Context Loading Specification

### Files to Include
**Dynamic Loading**: Load all `docs/*.md` files fresh for each command execution
- `docs/what-do-we-build.md` (project vision)
- `docs/architecture.md` (system design) 
- `docs/blueprint.md` (project structure)
- All other `docs/*.md` files found at runtime

### Size Limits and Input Validation
- **No Context Size Limit**: gflash supports 200K+ tokens (up to 1M), docs/*.md files are acceptable
- **User Input Limit**: 1000 words maximum unless `--big-user-input-allowed` flag provided
- **Size Reporting**: Show input size in KB and words when rejecting large inputs
- **Example**: `"Input too large: 15.2 KB, 2,431 words. Use --big-user-input-allowed to proceed"`

### Context Embedding Format
**Use embedded documents format (similar to code-review context):**
```xml
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
- **Dynamic Loading**: Fresh context load for each command (no caching)
- **Runtime Discovery**: Scan docs/ directory for all .md files at execution time
- **File Reading**: Read each file completely, embed in system prompt
- **Error Tolerance**: Continue with available files if some fail to load

### Fallback Behavior
**Minimum Guarantee**: Always save raw user input to ideas folder, regardless of context loading issues
- Show context loading errors to user
- Continue with whatever context successfully loaded
- Use embedded backup template if all context loading fails
- Save raw idea as absolute minimum functionality

## Example Workflow

```bash
ideas-manager capture "every task definition should have an example section"
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
```
input: tmp/20250730-1430-task-example-section.md
system: tmp/20250730-1430-task-example-section.system.prompt.md  
output: dev-taskflow/backlog/ideas/20250730-1430-task-example-section.md
```

### 2. **Save Raw Idea**
Creates temp input file with raw idea text at returned input path.

### 3. **Generate System Prompt** 
Creates temp system prompt with:
- Enhancement instructions using embedded template
- Project context from docs/*.md files
- LLM formatting constraints

### 4. **Call LLM Enhancement**
```bash
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
- **Retry Logic**: 3 attempts with exponential backoff (1s, 3s, 9s)
- **Fallback**: Save raw idea without enhancement if all retries fail
- **User Feedback**: 
  - Default: `"Enhancement failed, saved raw idea: [path]"`
  - Debug: Full API error details and retry attempts

#### 2. Slug Generation Failures  
- **Input Limit**: Send max 100 first words to LLM for slug generation
- **Fallback**: Use first 3 words from input, lowercase with hyphens
- **nav-path Responsibility**: If nav-path fails, use basic timestamp naming

#### 3. File System Failures
- **Pre-flight Checks**: Validate write permissions before processing
- **Atomic Operations**: Use temp files then move to final location
- **Cleanup**: Remove partial files on failure
- **User Feedback**:
  - Default: `"File creation failed, check permissions"`
  - Debug: Full path and permission details

#### 4. Input Processing Failures
- **Validation**: Minimum 5 characters required
- **Large Input Check**: Reject inputs over 1000 words unless `--big-user-input-allowed` flag provided
- **File Size Limit**: Max 10KB input files with truncation warning
- **Clipboard Fallback**: Prompt for manual input if clipboard fails
- **User Feedback**:
  - Default: `"Input too large: [X] KB, [Y] words. Use --big-user-input-allowed to proceed"`
  - Debug: Specific validation failure reason and input size details

#### 5. System Context Loading Failures
- **Template Missing**: Use embedded backup template
- **Context Files Unreadable**: Show errors, continue with available files, save raw idea as minimum
- **Dynamic Loading**: Load all docs/*.md files fresh for each command
- **User Feedback**:
  - Default: `"Context loading issues, saved raw idea: [path]"`
  - Debug: List of failed context files, sizes, and specific error reasons

### Debug Mode Behavior
- **Flag**: `--debug` shows detailed processing flow
- **Output**: All steps, retry attempts, fallback decisions to stdout
- **Error Details**: Full stack traces and API responses
- **No Logging**: Debug info only goes to stdout, no persistent logs

### Minimum Guarantee
**Tool will always:**
1. Save user input to `dev-taskflow/backlog/ideas/{timestamp}-{slug}.md`
2. Use project tmp directory (`tmp/`) not system temp
3. Provide meaningful file names even if slug generation fails
4. Return path to created file regardless of enhancement status

## Test Validation Approach

### Testing Strategy
**Unit Tests First, Then Integration Tests**

#### 1. Unit Test Requirements
- **Independent Tests**: Each test runs independently without dependencies
- **Component Focus**: Test individual atoms, molecules, and organisms separately
- **Fast Execution**: Unit tests should run quickly for development feedback
- **Failure Expected**: Tests should fail if commands/components don't exist yet
- **Real Data**: Tests can use real project data with proper cleanup

#### 2. Test Organization
```
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
```

#### 3. Test Categories

**Unit Tests (Primary)**
- Context loading functionality
- LLM client with retry logic
- Error handling with degraded functionality
- File creation and naming logic
- Input validation and size checking

**Integration Tests (Secondary)**
- End-to-end idea capture workflow
- Real project data with cleanup
- Cross-component interaction validation
- CLI interface testing

#### 4. Test Data Management
- **Use Real Project**: Tests can operate on actual project data
- **Cleanup Required**: All tests must clean up created files/directories
- **Isolation**: Tests must not interfere with each other
- **Deterministic**: Tests should produce consistent results

#### 5. Test Command Standards
- **Assume Tool Exists**: Test commands expect components to be implemented
- **Fail Fast**: Commands should fail immediately if prerequisites missing
- **Clear Assertions**: Each test has specific, testable assertions
- **Path Independence**: Tests work from project root or dev-tools directory

## Out of Scope

- ❌ Automatic task creation from ideas
- ❌ Idea prioritization or filtering
- ❌ Integration with task-manager
- ❌ Idea status tracking

## References

- Research document: dev-taskflow/current/v.0.3.0-workflows/backlog/research/how-to-build-planning-agents-without-loosing-control.md
- Existing idea: dev-taskflow/backlog/ideas/exe-capture-it-new.md
