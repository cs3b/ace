---
id: v.0.3.0+task.60
status: pending
priority: high
estimate: 6h
dependencies: []
---

# Fix System Prompt Handling in Review Code Workflow

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-handbook/guides | sed 's/^/    /'
```

_Result excerpt:_

```
    dev-handbook/guides
    ├── ai-agent-integration.g.md
    ├── atom-house-rules.md
    ├── changelog.g.md
    ├── code-review-process.g.md
    ├── coding-standards
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── coding-standards.g.md
    ├── debug-troubleshooting.g.md
    ├── documentation
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── documentation.g.md
    ├── documents-embedded-sync.g.md
    ├── documents-embedding.g.md
    ├── draft-release
    │   └── README.md
    ├── embedded-testing-guide.g.md
    ├── error-handling
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── error-handling.g.md
    ├── migration
    ├── performance
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── performance.g.md
    ├── project-management.g.md
    ├── quality-assurance
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── quality-assurance.g.md
    ├── README.md
    ├── release-codenames.g.md
    ├── release-publish
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── release-publish.g.md
    ├── roadmap-definition.g.md
    ├── security
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── security.g.md
    ├── strategic-planning.g.md
    ├── task-definition.g.md
    ├── temporary-file-management.g.md
    ├── test-driven-development-cycle
    │   ├── meta-documentation.md
    │   ├── ruby-application.md
    │   ├── ruby-gem.md
    │   ├── rust-cli.md
    │   ├── rust-wasm-zed.md
    │   ├── typescript-nuxt.md
    │   └── typescript-vue.md
    ├── testing
    │   ├── ruby-rspec-config-examples.md
    │   ├── ruby-rspec.md
    │   ├── rust.md
    │   └── typescript-bun.md
    ├── testing-tdd-cycle.g.md
    ├── testing.g.md
    ├── troubleshooting
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── version-control
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    └── version-control-system.g.md
    
    14 directories, 64 files
```

## Objective

Fix the critical system prompt handling flaw in the review-code workflow where system prompts are incorrectly embedded in combined prompts instead of using the proper `--system` flag. This architectural issue causes unnecessary prompt bloat and incorrect tool usage patterns, as identified in the reflection note analysis.

## Scope of Work

* Update the LLM execution section in `dev-handbook/workflow-instructions/review-code.wf.md` to use proper `--system` flag
* Remove system prompt embedding from combined prompt construction
* Ensure proper separation of system and user prompts in all LLM query examples
* Update template usage patterns to reflect correct system prompt handling
* Validate that all usage examples demonstrate proper parameter usage

### Deliverables

#### Create

* None (updating existing file)

#### Modify

* dev-handbook/workflow-instructions/review-code.wf.md

#### Delete

* None (removing problematic code sections)

## Phases

1. Audit current system prompt handling implementation
2. Identify all locations where system prompts are incorrectly embedded
3. Refactor LLM execution patterns to use `--system` flag
4. Update documentation and examples
5. Validate corrected implementation

## Implementation Plan

### Planning Steps

* [ ] Analyze current system prompt handling in review-code workflow
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: All problematic system prompt handling patterns are identified
  > Command: grep -n "system.prompt" dev-handbook/workflow-instructions/review-code.wf.md
* [ ] Research proper `--system` flag usage patterns in llm-query tool
* [ ] Plan detailed refactoring approach for multi-model execution sections

### Execution Steps

* [ ] Update the Multi-Model LLM Execution section (lines 308-350) to use `--system` flag instead of embedding system prompts
  > TEST: Verify System Flag Usage
  > Type: Action Validation
  > Assert: All llm-query commands use `--system` flag with proper template paths
  > Command: grep -A 3 -B 3 "llm-query.*--system" dev-handbook/workflow-instructions/review-code.wf.md
* [ ] Remove system prompt embedding from Combined Prompt Construction section (lines 217-295)
  > TEST: Verify System Prompt Removal
  > Type: Action Validation
  > Assert: System prompt content is not embedded in combined prompt construction
  > Command: grep -n "system.prompt" dev-handbook/workflow-instructions/review-code.wf.md
* [ ] Update all usage examples to demonstrate proper `--system` flag usage
  > TEST: Verify Example Consistency
  > Type: Action Validation
  > Assert: All examples show correct system prompt parameter usage
  > Command: grep -n "dev-tools/exe/llm-query" dev-handbook/workflow-instructions/review-code.wf.md
* [ ] Update template selection documentation to clarify system prompt file usage
* [ ] Validate that corrected implementation matches reflection note recommendations

## Acceptance Criteria

* [ ] All LLM query commands use `--system` flag with proper template file paths
* [ ] System prompt content is completely removed from combined prompt construction
* [ ] All usage examples demonstrate correct system prompt parameter usage
* [ ] Template selection section properly documents system prompt file usage
* [ ] Implementation matches the corrected pattern from reflection note: `llm-query gpro --system system-prompt.md --timeout 500 --output gpro-review.md "$(cat content-prompt.md)"`

## Out of Scope

* ❌ Updating other workflow files (focus only on review-code.wf.md)
* ❌ Modifying the actual template files (only updating how they're used)
* ❌ Implementing the `--output` flag usage (separate task)
* ❌ Creating new template files

## References

* Source issue: dev-taskflow/current/v.0.3.0-workflows/reflections/20250705-173751-handbook-review-system-prompt-improvements.md
* Target file: dev-handbook/workflow-instructions/review-code.wf.md
* Reflection note analysis: System Prompt Architecture Flaw (lines 36-39)
* Corrected implementation pattern: lines 120-123 in reflection note
