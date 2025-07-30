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
  > Command: grep -r "llm-query" dev-tools/exe/ && ls dev-tools/lib/coding_agent_tools/organisms/
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
  > TEST: Organism Implementation Check
  > Type: Component Validation
  > Assert: IdeaCapture follows ATOM architecture and has required methods
  > Command: ruby -r ./dev-tools/lib/coding_agent_tools -e "puts CodingAgentTools::Organisms::IdeaCapture.new.respond_to?(:capture)"
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
- [ ] Implement timestamped file creation logic with proper error handling
- [ ] Add validation for release parameter and directory creation
- [ ] Implement LLM integration with retry logic and fallback handling
  > TEST: LLM Integration Check
  > Type: Integration Validation
  > Assert: Tool successfully calls llm-query and handles responses
  > Command: ideas-manager capture "test idea" --debug
- [ ] Implement error handling with degraded functionality guarantees
  > TEST: Error Handling Validation
  > Type: Failure Mode Testing  
  > Assert: Tool saves raw idea even when LLM/nav-path fails
  > Command: ideas-manager capture "test failure scenario" --debug (with simulated failures)
- [ ] Create comprehensive tests in dev-tools/spec/ (unit and integration)
- [ ] Update dev-tools documentation and tools.md reference

## Scope of Work

### Deliverables

#### Create
- dev-tools/exe/ideas-manager
- dev-tools/lib/coding_agent_tools/organisms/idea_capture.rb
- dev-tools/lib/coding_agent_tools/molecules/idea_enhancer.rb
- dev-tools/spec/organisms/idea_capture_spec.rb
- dev-tools/spec/cli/ideas_manager_spec.rb
- dev-handbook/templates/idea-manager/system.prompt.md (LLM system prompt with project context)
- dev-handbook/templates/idea-manager/idea.template.md (structured idea format template)

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
- Project context from docs/*.md files
- Output formatting constraints

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
- **File Size Limit**: Max 10KB input files with truncation warning
- **Clipboard Fallback**: Prompt for manual input if clipboard fails
- **User Feedback**:
  - Default: `"Invalid input, please try again"`
  - Debug: Specific validation failure reason

#### 5. System Context Loading Failures
- **Template Missing**: Use embedded backup template
- **Context Files Unreadable**: Continue with minimal template
- **Size Limits**: Truncate context if too large, prioritize essential docs
- **User Feedback**:
  - Default: `"Using basic template due to context issues"`
  - Debug: List of failed context files and reasons

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

## Out of Scope

- ❌ Automatic task creation from ideas
- ❌ Idea prioritization or filtering
- ❌ Integration with task-manager
- ❌ Idea status tracking

## References

- Research document: dev-taskflow/current/v.0.3.0-workflows/backlog/research/how-to-build-planning-agents-without-loosing-control.md
- Existing idea: dev-taskflow/backlog/ideas/exe-capture-it-new.md
