---
id: v.0.3.0+task.62
status: done
priority: medium
estimate: 4h
dependencies: [v.0.3.0+task.60]
---

# Implement Direct Output Usage with Cost Tracking

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

Implement direct output usage with the `--output` flag in the review-code workflow to enable cost tracking and usage metrics capture. This enhancement will provide better monitoring capabilities and enable cost analysis and optimization opportunities, addressing the missing direct output usage identified in the reflection note.

## Scope of Work

* Update LLM execution patterns in `.ace/handbook/workflow-instructions/review-code.wf.md` to use `--output` flag
* Modify execution examples to demonstrate direct file output capabilities
* Update session finalization to leverage enhanced reporting from direct output
* Ensure cost information and usage metrics are properly captured
* Update documentation to highlight the benefits of direct output usage

### Deliverables

#### Create

* None (updating existing file)

#### Modify

* .ace/handbook/workflow-instructions/review-code.wf.md

#### Delete

* None

## Phases

1. Audit current output handling in review-code workflow
2. Identify all LLM execution patterns that need --output flag
3. Update multi-model execution section with direct output usage
4. Enhance session finalization to leverage cost tracking data
5. Update documentation to explain direct output benefits

## Implementation Plan

### Planning Steps

* [ ] Analyze current output handling patterns in review-code workflow
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: All LLM execution patterns without --output flag are identified
  > Command: grep -n ".ace/tools/exe/llm-query" .ace/handbook/workflow-instructions/review-code.wf.md | grep -v "\-\-output"
* [ ] Research available cost tracking information from --output flag
* [ ] Plan integration of cost tracking into session summary

### Execution Steps

* [x] Update Multi-Model LLM Execution section to use --output flag for all LLM queries
  > TEST: Verify Output Flag Usage
  > Type: Action Validation
  > Assert: All llm-query commands use --output flag with proper file paths
  > Command: grep -A 2 -B 2 "llm-query.*--output" .ace/handbook/workflow-instructions/review-code.wf.md
* [x] Update execution status checks to validate output file creation
  > TEST: Verify Output File Validation
  > Type: Action Validation
  > Assert: Execution status checks verify output file existence and content
  > Command: grep -n "test -f.*\.md" .ace/handbook/workflow-instructions/review-code.wf.md
* [ ] Enhance session finalization to include cost tracking information
  > TEST: Verify Cost Tracking Integration
  > Type: Action Validation
  > Assert: Session summary includes cost and usage metrics when available
  > Command: grep -n "cost\|usage\|metrics" .ace/handbook/workflow-instructions/review-code.wf.md
* [x] Update all usage examples to demonstrate --output flag benefits
* [ ] Add documentation section explaining direct output advantages

## Acceptance Criteria

* [x] All LLM query commands use --output flag with proper file paths
* [x] Execution status checks validate output file creation and content
* [ ] Session finalization includes cost tracking information when available
* [x] Usage examples demonstrate direct output flag benefits
* [ ] Documentation explains advantages of direct output usage (cost tracking, usage metrics)

## Out of Scope

* ❌ Modifying the actual llm-query tool implementation
* ❌ Creating new cost analysis tools
* ❌ Implementing automatic cost alerts or limits
* ❌ Updating other workflow files (focus only on review-code.wf.md)

## References

* Source issue: .ace/taskflow/current/v.0.3.0-workflows/reflections/20250705-173751-handbook-review-system-prompt-improvements.md
* Target file: .ace/handbook/workflow-instructions/review-code.wf.md
* Reflection note analysis: Missing Direct Output Usage (lines 41-44)
* Benefits documentation: lines 125-129 in reflection note
* Dependent task: v.0.3.0+task.60 (Fix System Prompt Handling in Review Code Workflow)
