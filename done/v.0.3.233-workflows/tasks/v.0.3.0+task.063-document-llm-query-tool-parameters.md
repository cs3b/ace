---
id: v.0.3.0+task.63
status: done
priority: medium
estimate: 5h
dependencies: []
---

# Document LLM Query Tool Parameters

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 .ace/handbook/guides | sed 's/^/    /'
```

_Result excerpt:_

```
    .ace/handbook/guides
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

Create comprehensive documentation of all available llm-query tool parameters and usage patterns to prevent future knowledge gaps about tool capabilities. This addresses the tool parameter knowledge gap identified in the reflection note, ensuring that all team members understand the full capabilities of the llm-query tool.

## Scope of Work

* Create detailed documentation of all llm-query tool parameters
* Include usage patterns and best practices for each parameter
* Document provider-specific considerations and model availability
* Create practical examples demonstrating various parameter combinations
* Establish reference guide for proper tool usage in workflows

### Deliverables

#### Create

* .ace/handbook/guides/llm-query-tool-reference.g.md

#### Modify

* None

#### Delete

* None

## Phases

1. Audit llm-query tool capabilities and parameters
2. Research provider-specific features and limitations
3. Document comprehensive parameter reference
4. Create usage patterns and best practices guide
5. Validate documentation with practical examples

## Implementation Plan

### Planning Steps

* [x] Research llm-query tool implementation to understand all available parameters
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: All available parameters and their functions are identified
  > Command: .ace/tools/exe/llm-query --help || grep -r "option\|parameter" .ace/tools/
* [x] Test various parameter combinations to understand interactions
* [x] Research provider-specific capabilities and limitations

### Execution Steps

* [x] Create comprehensive parameter reference section
  > TEST: Verify Parameter Coverage
  > Type: Action Validation
  > Assert: All available parameters are documented with descriptions
  > Command: grep -c "###.*--" .ace/handbook/guides/llm-query-tool-reference.g.md
* [x] Document usage patterns for common scenarios (system prompts, output files, timeouts)
  > TEST: Verify Usage Patterns
  > Type: Action Validation
  > Assert: Usage patterns section includes practical examples
  > Command: grep -n "Usage Pattern\|Example" .ace/handbook/guides/llm-query-tool-reference.g.md
* [x] Add provider-specific considerations and model availability
  > TEST: Verify Provider Documentation
  > Type: Action Validation
  > Assert: Provider-specific features and limitations are documented
  > Command: grep -n "google\|anthropic\|provider" .ace/handbook/guides/llm-query-tool-reference.g.md
* [x] Create best practices section based on reflection note learnings
* [x] Add troubleshooting section for common parameter-related issues
* [x] Include cross-references to workflow files that use llm-query

## Acceptance Criteria

* [x] All available llm-query parameters are documented with clear descriptions
* [x] Usage patterns section includes practical examples for common scenarios
* [x] Provider-specific considerations and model availability are documented
* [x] Best practices section addresses issues identified in reflection note
* [x] Troubleshooting section covers common parameter-related problems
* [x] Cross-references to workflow files using llm-query are included

## Out of Scope

* ❌ Modifying the actual llm-query tool implementation
* ❌ Creating new llm-query parameters or features
* ❌ Updating all existing workflow files to reference this documentation
* ❌ Creating integration with other tools beyond llm-query

## References

* Source issue: .ace/taskflow/current/v.0.3.0-workflows/reflections/20250705-173751-handbook-review-system-prompt-improvements.md
* Target file: .ace/handbook/guides/llm-query-tool-reference.g.md (to be created)
* Reflection note analysis: Tool Parameter Knowledge Gap (lines 18-21)
* Tool location: .ace/tools/exe/llm-query
* Related usage: .ace/handbook/workflow-instructions/review-code.wf.md (lines 312, 325)
