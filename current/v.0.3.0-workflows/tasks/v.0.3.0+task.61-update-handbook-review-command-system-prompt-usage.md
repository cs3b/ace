---
id: v.0.3.0+task.61
status: pending
priority: high
estimate: 3h
dependencies: [v.0.3.0+task.60]
---

# Update Handbook Review Command System Prompt Usage

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

Update the handbook review command wrapper to correctly specify system prompt parameter usage and reference the proper system prompt handling approach, ensuring consistency with the fixed review-code workflow implementation. The current command wrapper references an incorrect system prompt path and doesn't align with the corrected implementation.

## Scope of Work

* Update `.claude/commands/handbook-review.md` to reference correct system prompt handling
* Ensure command wrapper documentation aligns with corrected workflow implementation
* Update the system prompt file path reference if needed
* Validate that the command execution examples reflect proper parameter usage
* Ensure consistency with the fixed review-code workflow patterns

### Deliverables

#### Create

* None (updating existing file)

#### Modify

* .claude/commands/handbook-review.md

#### Delete

* None

## Phases

1. Audit current handbook review command implementation
2. Identify inconsistencies with corrected workflow patterns
3. Update command wrapper documentation
4. Validate system prompt file path references
5. Ensure command execution examples are correct

## Implementation Plan

### Planning Steps

* [ ] Analyze current handbook review command implementation
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Current command wrapper structure and system prompt references are identified
  > Command: grep -n "system" .claude/commands/handbook-review.md
* [ ] Compare with corrected review-code workflow patterns
* [ ] Verify system prompt file path exists and is correct

### Execution Steps

* [ ] Update system prompt file path reference to use correct location
  > TEST: Verify System Prompt Path
  > Type: Action Validation
  > Assert: System prompt path reference is correct and file exists
  > Command: test -f "$(grep -o 'dev-.*\.md' .claude/commands/handbook-review.md | head -1)" && echo "System prompt file exists"
* [ ] Update command execution documentation to reflect proper system prompt handling
  > TEST: Verify Command Documentation
  > Type: Action Validation
  > Assert: Command execution examples show correct system prompt parameter usage
  > Command: grep -n "system-prompt" .claude/commands/handbook-review.md
* [ ] Ensure the command wrapper correctly references the handbook-specific system prompt template
* [ ] Update the command execution section to align with corrected workflow patterns
* [ ] Validate that all pre-configured parameters documentation is accurate

## Acceptance Criteria

* [ ] System prompt file path reference is correct and points to existing file
* [ ] Command execution documentation reflects proper system prompt handling
* [ ] Command wrapper documentation is consistent with corrected review-code workflow
* [ ] All pre-configured parameters are accurately documented
* [ ] Handbook-specific system prompt template is properly referenced

## Out of Scope

* ❌ Modifying the actual system prompt template files
* ❌ Changing the command wrapper functionality (only documentation)
* ❌ Updating other Claude commands (focus only on handbook-review)
* ❌ Creating new system prompt files

## References

* Source issue: dev-taskflow/current/v.0.3.0-workflows/reflections/20250705-173751-handbook-review-system-prompt-improvements.md
* Target file: .claude/commands/handbook-review.md
* Dependent task: v.0.3.0+task.60 (Fix System Prompt Handling in Review Code Workflow)
* Current system prompt reference: `dev-local/handbook/tpl/review/system.prompt.md` (line 24)