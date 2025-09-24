---

id: v.0.3.0+task.01
status: done
priority: high
estimate: 4h
dependencies: []
---

# Create Comprehensive Tools Documentation

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 docs | sed 's/^/    /'
```

_Result excerpt:_

```
    docs
    ├── architecture.md
    ├── blueprint.md
    └── what-do-we-build.md
```

## Objective

Create a comprehensive reference document for all current development tools in the project, documenting the current state of bin/ and .ace/tools/exe/ commands in .ace/tools/docs/tools.md with symlink access from docs/tools.md.

## Scope of Work

* Document current state of development tools (not planned future tools)
* Document all current .ace/tools/exe/ executables (~7 tools) with usage examples
* Document all bin/ commands (~20 scripts)
* Create categorized reference (Git tools, Task management, Quality tools, LLM tools)
* Include setup requirements and dependencies
* Create workflow instruction for future updates during migration
* Focus on coding agent usability with key examples

### Deliverables

#### Create

* .ace/tools/docs/tools.md (primary document)
* .ace/local/wfi/update-docs-tools.wf.md (workflow instruction)
* docs/tools.md (symlink to .ace/tools/docs/tools.md)

#### Modify

* docs/blueprint.md (update to reference tools.md symlink)

#### Delete

* None

## Phases

1. Audit current tool inventory (bin/ and .ace/tools/exe/)
2. Create .ace/tools/docs/ directory structure
3. Document current state in .ace/tools/docs/tools.md
4. Create workflow instruction for future updates
5. Create symlink and update blueprint.md reference

## Implementation Plan

### Planning Steps

* [x] Audit current bin/ directory to inventory all development scripts
  > TEST: Bin Directory Audit Complete
  > Type: Pre-condition Check
  > Assert: All bin/ scripts are identified and categorized
  > Command: ls -la bin/ | wc -l
* [x] Audit current .ace/tools/exe/ directory to inventory all gem executables
  > TEST: Exe Directory Audit Complete
  > Type: Pre-condition Check
  > Assert: All .ace/tools/exe/ executables are identified
  > Command: ls -la .ace/tools/exe/ | wc -l
* [x] Research current tool usage patterns from blueprint.md for reference

### Execution Steps

- [x] Create .ace/tools/docs/ directory structure
- [x] Create .ace/tools/docs/tools.md with standard header and current tool inventory
- [x] Document Git workflow tools (bin/gc, bin/gl, bin/gp, bin/gpull)
  > TEST: Git Tools Section Complete
  > Type: Content Validation
  > Assert: All git-related bin/ commands are documented
  > Command: grep -c "^## Git" .ace/tools/docs/tools.md
- [x] Document Task management tools (bin/tn, bin/tr, bin/tal, bin/tnid, bin/rc)
- [x] Document Quality/Testing tools (bin/test, bin/lint, bin/build)
- [x] Document LLM tools (.ace/tools/exe/llm-*)
- [x] Document Development utilities (bin/console, bin/tree, bin/cr*)
- [x] Add setup requirements and dependencies section
- [x] Create workflow instruction .ace/local/wfi/update-docs-tools.wf.md
- [x] Create symlink from docs/tools.md to .ace/tools/docs/tools.md
  > TEST: Symlink Created
  > Type: File System Validation
  > Assert: Symlink exists and points to correct target
  > Command: ls -la docs/tools.md | grep -c ".ace/tools/docs/tools.md"
- [x] Update blueprint.md to reference tools.md symlink
  > TEST: Blueprint Updated
  > Type: Content Validation
  > Assert: blueprint.md references tools.md symlink
  > Command: grep -c "tools.md" docs/blueprint.md

## Acceptance Criteria

* [x] .ace/tools/docs/tools.md contains comprehensive current tool documentation
* [x] All current .ace/tools/exe/ executables are documented with usage examples
* [x] All bin/ commands are documented with descriptions
* [x] Tools are organized by category (Git, Task Management, Quality, LLM, etc.)
* [x] Setup requirements and dependencies are clearly stated
* [x] Workflow instruction created for future updates during migration
* [x] Symlink from docs/tools.md to .ace/tools/docs/tools.md works correctly
* [x] Documentation is brief but informative for coding agent usage

## Out of Scope

* ❌ Creating new tools or modifying existing tool functionality
* ❌ Documenting planned future tools (only current state)
* ❌ Updating workflow documentation beyond blueprint.md and the new workflow instruction

## References

* Primary target location: .ace/tools/docs/tools.md
* Symlink location: docs/tools.md
* Workflow instruction location: .ace/local/wfi/update-docs-tools.wf.md
* Current blueprint.md location: docs/blueprint.md
* Related task from original plan: task.54