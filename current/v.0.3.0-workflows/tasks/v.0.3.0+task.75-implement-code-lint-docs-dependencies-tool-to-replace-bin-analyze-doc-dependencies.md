---
id: v.0.3.0+task.75
status: pending
priority: medium
estimate: 6h
dependencies: []
---

# Implement code-lint docs-dependencies Tool to Replace bin/analyze-doc-dependencies

## 0. Directory Audit ✅

_Command run:_

```bash
wc -l bin/analyze-doc-dependencies && ls -la dev-tools/lib/coding_agent_tools/cli/commands/ | grep lint
```

_Result excerpt:_

```
bin/analyze-doc-dependencies: 217 lines of Ruby code for doc dependency analysis
dev-tools has code-lint infrastructure but no docs-dependencies command yet
```

## Objective

Migrate the documentation dependency analysis functionality from `bin/analyze-doc-dependencies` into the CAT gem architecture as a new `code-lint docs-dependencies` command. This will provide the same dependency analysis, circular dependency detection, and DOT graph generation within the unified CAT toolset.

## Scope of Work

- Analyze the existing bin/analyze-doc-dependencies Ruby script functionality
- Implement equivalent functionality within the CAT gem using ATOM architecture
- Create code-lint docs-dependencies command with same capabilities
- Migrate DOT graph generation and JSON output features
- Replace all references to the old bin script
- Remove the deprecated bin script after migration

### Deliverables

#### Create

- dev-tools/lib/coding_agent_tools/cli/commands/code_lint/docs_dependencies.rb
- dev-tools/lib/coding_agent_tools/organisms/doc_dependency_analyzer.rb
- dev-tools/lib/coding_agent_tools/molecules/doc_link_parser.rb
- dev-tools/lib/coding_agent_tools/atoms/file_reference_extractor.rb
- dev-tools/spec/unit/cli/commands/code_lint/docs_dependencies_spec.rb
- dev-tools/spec/unit/organisms/doc_dependency_analyzer_spec.rb

#### Modify

- dev-tools/lib/coding_agent_tools/cli/commands/code_lint.rb (add subcommand)
- All documentation referencing bin/analyze-doc-dependencies
- Blueprint.md and other architectural documentation

#### Delete

- bin/analyze-doc-dependencies (after migration complete)

## Implementation Plan

### Planning Steps

- [ ] Analyze existing bin/analyze-doc-dependencies script to understand all functionality
  > TEST: Functionality Analysis Complete
  > Type: Pre-condition Check
  > Assert: All features and capabilities of the original script are documented
  > Command: ruby bin/analyze-doc-dependencies --help 2>/dev/null || echo "Script analyzed"
- [ ] Design ATOM architecture components (Atoms, Molecules, Organisms) for doc analysis
- [ ] Plan integration with existing code-lint command structure
- [ ] Design CLI interface to match or improve upon original functionality

### Execution Steps

- [ ] Create FileReferenceExtractor atom for finding markdown links and file references
- [ ] Create DocLinkParser molecule for parsing and resolving relative/absolute links
- [ ] Create DocDependencyAnalyzer organism for complete dependency analysis logic
- [ ] Implement docs-dependencies CLI command as code-lint subcommand
- [ ] Add DOT graph generation functionality (preserving .dot and .png output)
- [ ] Add JSON export functionality for programmatic access
- [ ] Implement circular dependency detection and orphaned file identification
- [ ] Add comprehensive unit tests for all new components
  > TEST: Verify Migration Completeness
  > Type: Action Validation
  > Assert: New CAT tool provides equivalent functionality to original script
  > Command: code-lint docs-dependencies && diff -u <(bin/analyze-doc-dependencies) <(code-lint docs-dependencies)
- [ ] Update all documentation references to use new command
- [ ] Remove deprecated bin/analyze-doc-dependencies script

## Acceptance Criteria

- [ ] AC 1: `code-lint docs-dependencies` command provides all functionality of original script
- [ ] AC 2: DOT graph and JSON output formats are preserved and equivalent
- [ ] AC 3: All original features work: circular dependency detection, orphaned files, statistics
- [ ] AC 4: New implementation follows ATOM architecture with comprehensive tests
- [ ] AC 5: All documentation references are updated and deprecated script is removed

## Out of Scope

- ❌ Adding new features beyond original script capabilities
- ❌ Changing output formats or analysis algorithms
- ❌ Modifying other code-lint subcommands

## References

- Current bin/analyze-doc-dependencies implementation (217 lines)
- CAT gem ATOM architecture documentation
- Existing code-lint command structure in dev-tools
- Blueprint documentation referencing the analysis tool