---

id: v.0.3.0+task.21
status: done
priority: medium
estimate: 8h
dependencies: [v.0.3.0+task.18]
---

# Implement Code Review Synthesis Command

## 0. Directory Audit ✅

_Command run:_

```bash
ls -la .ace/handbook/workflow-instructions/synthesize-reviews.wf.md 2>/dev/null | sed 's/^/    /'
```

_Result excerpt:_

```
    .ace/handbook/workflow-instructions/synthesize-reviews.wf.md
```

## Objective

Implement a Ruby-based `code-review-synthesize` command that orchestrates LLM calls to synthesize multiple code review reports into a unified analysis, following the project's established ATOM architecture and CLI patterns.

## Scope of Work

* Create `code-review-synthesize` executable following ExecutableWrapper pattern
* Implement CLI command with multiple report input support
* Add LLM orchestration using existing `llm-query` infrastructure
* Support automatic session directory inference from report paths
* Implement intelligent output file sequencing (preserve existing LLM results)
* Default integration with synthesis system prompt template

### Deliverables

#### Create

* `.ace/tools/exe/code-review-synthesize` - Executable wrapper
* `lib/coding_agent_tools/cli/commands/code/review_synthesize.rb` - CLI command implementation
* `lib/coding_agent_tools/molecules/code/report_collector.rb` - Report collection and validation
* `lib/coding_agent_tools/molecules/code/session_path_inferrer.rb` - Session directory inference
* `lib/coding_agent_tools/molecules/code/synthesis_orchestrator.rb` - LLM query orchestration

#### Modify

* `lib/coding_agent_tools/cli.rb` - Add command registration method
* `lib/coding_agent_tools/molecules/file_io_handler.rb` - Add sequenced file output support (if needed)

#### Delete

* None

## Phases

1. Create executable and CLI command structure
2. Implement report collection and session inference
3. Add LLM orchestration with existing infrastructure
4. Implement intelligent output file handling
5. Test with existing review sessions

## Implementation Plan

### Planning Steps

* [x] Analyze existing CLI command patterns in codebase
  > TEST: Pattern Analysis
  > Type: Pre-condition Check
  > Assert: CLI patterns understood
  > Command: find .ace/tools/lib/coding_agent_tools/cli/commands -name "*.rb" | wc -l
* [x] Study llm-query integration requirements
* [x] Design CLI interface following established patterns
* [x] Plan ATOM component architecture

### Execution Steps

- [x] Create executable wrapper `.ace/tools/exe/code-review-synthesize`
- [x] Implement CLI command `cli/commands/code/review_synthesize.rb`
  > TEST: Command Registration
  > Type: CLI Test
  > Assert: Command properly registered
  > Command: cd .ace/tools && exe/code-review-synthesize --help
- [x] Create ReportCollector molecule for file input handling
- [x] Implement SessionPathInferrer molecule for directory inference
- [x] Create SynthesisOrchestrator molecule for llm-query integration
  > TEST: LLM Integration
  > Type: Integration Test
  > Assert: llm-query called with correct parameters
  > Command: cd .ace/tools && exe/code-review-synthesize --dry-run test-reports/*.md
- [x] Add command registration to CLI module
- [x] Implement intelligent output file sequencing
  > TEST: File Sequencing
  > Type: File Operation Test
  > Assert: Existing files preserved with sequence numbers
  > Command: cd .ace/tools && bin/test spec/cli/commands/code/review_synthesize_spec.rb
- [x] Test with existing review session data

## Acceptance Criteria

* [x] CLI command accepts multiple report files as arguments (minimum 2)
* [x] Session directory automatically inferred from first report path
* [x] Default output follows pattern: `<prefix>-report.md` (e.g., `cr-report.md`)
* [x] Existing output files preserved with sequence numbers (`.1.md`, `.2.md`, etc.)
* [x] Default system prompt uses `.ace/handbook/templates/review-synthesizer/system.prompt.md`
* [x] LLM provider/model defaults to `google:gemini-2.5-pro`, supports all llm-query providers
* [x] Integration with existing FileIoHandler and FormatHandlers molecules
* [x] Command properly registered in CLI and accessible via executable

## Out of Scope

* ❌ Creating new LLM client implementations (reuse existing)
* ❌ Implementing custom synthesis logic (delegate to LLM)
* ❌ Modifying existing review session structure
* ❌ Creating bash-based implementations (Ruby only)

## References

* Dependency: v.0.3.0+task.18 (existing CLI infrastructure)
* Source: .ace/handbook/workflow-instructions/synthesize-reviews.wf.md (workflow requirements)
* Pattern references: `exe/llm-query`, `cli/commands/llm/query.rb`, `cli/commands/code/review.rb`
* System prompt template: `.ace/handbook/templates/review-synthesizer/system.prompt.md`
* Architecture: ATOM pattern with ExecutableWrapper molecule
* Integration: Existing llm-query infrastructure and FileIoHandler

## CLI Interface Specification

```bash
code-review-synthesize <report1> <report2> [report3...] [options]
  --model <provider:model>     # LLM model (default: gpro)
  --output <file>             # Output file (default: inferred from session)
  --format <format>           # Output format (default: markdown)
  --system-prompt <file>      # Custom system prompt (default: template)
  --force                     # Force overwrite existing files
  --debug                     # Debug mode
  --help                      # Show help
```

### Examples

```bash
# Basic synthesis with default model (gpro)
code-review-synthesize cr-report-claude-opus.md cr-report-gpt4.md

# Custom model
code-review-synthesize cr-report-*.md --model anthropic:claude-4-0-sonnet-latest

# Custom output location
code-review-synthesize cr-report-*.md --output final-synthesis.md

# With force overwrite
code-review-synthesize cr-report-*.md --force
```