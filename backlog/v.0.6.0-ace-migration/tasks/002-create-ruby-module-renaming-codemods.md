---
id: v.0.6.0+task.002
status: pending
priority: high
estimate: 6h
dependencies: []
---

# Create Ruby Module Renaming Codemods

## Objective

Create codemods to rename all references from `CodingAgentTools` to `AceTools` throughout the Ruby codebase, including module names, file paths, and gem references.

## Scope of Work

- Rename Ruby module from CodingAgentTools to AceTools
- Update all file paths from coding_agent_tools to ace_tools
- Update gem name references
- Handle require statements and autoload paths

### Deliverables

#### Create

- `codemods/rename_ruby_module.rb` - Ruby module renaming codemod
- `codemods/rename_files.sh` - Shell script for file/directory renaming
- `codemods/module_mappings.yml` - Configuration for module mappings

#### Modify

- None (new files only in this task)

#### Delete

- None

## Implementation Plan

### Planning Steps

* [ ] Inventory all CodingAgentTools module references (2,991 occurrences)
* [ ] Map out file renaming requirements
* [ ] Plan for maintaining git history during renames

### Execution Steps

- [ ] Create `rename_ruby_module.rb` codemod with features:
  - Module name substitution (CodingAgentTools → AceTools)
  - Snake_case path updates (coding_agent_tools → ace_tools)
  - Dash-case updates (coding-agent-tools → ace-tools)
  - Require statement updates
  - Autoload path updates
  - String reference updates
  > TEST: Module Renaming Verification
  > Type: Pattern Match Test
  > Assert: No CodingAgentTools references remain
  > Command: grep -r "CodingAgentTools" .ace/tools/lib --include="*.rb"

- [ ] Create `rename_files.sh` script for:
  - Renaming lib/coding_agent_tools/ → lib/ace_tools/
  - Renaming lib/coding_agent_tools.rb → lib/ace_tools.rb
  - Renaming sig/coding_agent_tools.rbs → sig/ace_tools.rbs
  - Renaming exe/coding-agent-tools → exe/ace-tools
  - Updating gemspec filename
  > TEST: File Structure Verification
  > Type: Directory Check
  > Assert: New directory structure exists
  > Command: ls -la .ace/tools/lib/ace_tools/

- [ ] Create module_mappings.yml configuration:
  ```yaml
  modules:
    CodingAgentTools: AceTools
  paths:
    coding_agent_tools: ace_tools
    coding-agent-tools: ace-tools
  files:
    "lib/coding_agent_tools": "lib/ace_tools"
    "lib/coding_agent_tools.rb": "lib/ace_tools.rb"
  ```

## Acceptance Criteria

- [ ] All Ruby module references updated
- [ ] All file paths correctly renamed
- [ ] Git history preserved for renamed files
- [ ] Require statements work with new paths
- [ ] Autoloading continues to function

## Out of Scope

- ❌ Path updates in documentation (task 001)
- ❌ Configuration file updates (task 003)
- ❌ Test execution (task 005)