---
id: v.0.6.0+task.007
status: pending
priority: medium
estimate: 2h
dependencies: [v.0.6.0+task.006]
---

# Create Migration Guide for Users

## Objective

Create a comprehensive migration guide to help existing users transition from the old `coding-agent-tools` gem and `dev-*` structure to the new `ace-tools` gem and `.ace/*` structure.

## Scope of Work

- Document all breaking changes
- Provide step-by-step migration instructions
- Include troubleshooting section
- Create compatibility notes

### Deliverables

#### Create

- `docs/MIGRATION_v0.6.0.md` - Detailed migration guide
- `.ace/tools/UPGRADING.md` - Gem-specific upgrade guide
- `scripts/migrate_project.sh` - Automated migration helper script

#### Modify

- `README.md` - Add migration notice and link

#### Delete

- None

## Implementation Plan

### Planning Steps

* [ ] List all breaking changes for users
* [ ] Identify common migration scenarios
* [ ] Plan automation possibilities

### Execution Steps

- [ ] Create comprehensive migration guide:
  ```markdown
  # Migration Guide: CodingAgentTools to AceTools (v0.6.0)

  ## Overview
  Version 0.6.0 introduces major changes...

  ## Breaking Changes
  ### Gem Name Change
  - Old: `gem 'coding-agent-tools'`
  - New: `gem 'ace-tools'`

  ### Module Name Change
  - Old: `require 'coding_agent_tools'`
  - New: `require 'ace_tools'`
  - Old: `CodingAgentTools::CLI`
  - New: `AceTools::CLI`

  ### Directory Structure
  - Old: `dev-tools/`, `dev-handbook/`, `dev-taskflow/`
  - New: `.ace/tools/`, `.ace/handbook/`, `.ace/taskflow/`

  ## Migration Steps
  ### For Gem Users
  1. Update Gemfile
  2. Update require statements
  3. Update module references
  4. Run bundle update

  ### For Repository Users
  1. Pull latest changes
  2. Update git submodules
  3. Update shell configuration
  4. Source new setup scripts

  ## Troubleshooting
  - Issue: "cannot load such file -- coding_agent_tools"
    Solution: Update to `require 'ace_tools'`
  ...
  ```
  > TEST: Guide Completeness
  > Type: Documentation Review
  > Assert: All breaking changes documented
  > Command: grep -c "Breaking Changes" docs/MIGRATION_v0.6.0.md

- [ ] Create automated migration script:
  ```bash
  #!/bin/bash
  # migrate_project.sh - Helps migrate existing projects

  echo "ACE Tools Migration Assistant"
  echo "============================="

  # Check for old gem
  if gem list | grep -q "coding-agent-tools"; then
    echo "Found old gem, uninstalling..."
    gem uninstall coding-agent-tools
  fi

  # Update Gemfile if exists
  if [ -f "Gemfile" ]; then
    sed -i '' "s/coding-agent-tools/ace-tools/g" Gemfile
    echo "Updated Gemfile"
  fi

  # Update Ruby files
  find . -name "*.rb" -type f -exec \
    sed -i '' "s/coding_agent_tools/ace_tools/g" {} \;
  find . -name "*.rb" -type f -exec \
    sed -i '' "s/CodingAgentTools/AceTools/g" {} \;

  echo "Migration complete!"
  ```
  > TEST: Migration Script
  > Type: Shell Test
  > Assert: Script runs without errors
  > Command: bash -n scripts/migrate_project.sh

- [ ] Create gem-specific upgrade guide:
  - Focus on Ruby API changes
  - Include code examples
  - Show before/after comparisons

- [ ] Update README with migration notice:
  ```markdown
  > **📢 Important: Version 0.6.0 Breaking Changes**
  >
  > The gem has been renamed from `coding-agent-tools` to `ace-tools`.
  > See [Migration Guide](docs/MIGRATION_v0.6.0.md) for upgrade instructions.
  ```

## Acceptance Criteria

- [ ] Migration guide covers all breaking changes
- [ ] Step-by-step instructions are clear
- [ ] Automation script works for common cases
- [ ] Troubleshooting covers known issues
- [ ] README prominently displays migration notice

## Out of Scope

- ❌ Backward compatibility layer
- ❌ Automatic rollback functionality
- ❌ Database migration scripts