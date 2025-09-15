---
id: v.0.6.0+task.009
status: pending
priority: low
estimate: 2h
dependencies: [v.0.6.0+task.008]
---

# Post-Migration Cleanup

## Objective

Clean up temporary files, remove old references, archive migration scripts, and ensure the codebase is clean after the migration.

## Scope of Work

- Remove temporary codemods directory
- Clean up backup files
- Archive migration scripts
- Update CI/CD configurations
- Final verification sweep

### Deliverables

#### Create

- `docs/archive/v0.6.0-migration/` - Archived migration scripts

#### Modify

- `.gitignore` - Remove temporary entries
- CI/CD configuration files

#### Delete

- `codemods/` directory (after archiving)
- Temporary backup directories
- Old gem build files

## Implementation Plan

### Planning Steps

* [ ] List all temporary files/directories
* [ ] Identify what should be archived vs deleted
* [ ] Plan CI/CD updates needed

### Execution Steps

- [ ] Archive migration scripts:
  ```bash
  mkdir -p docs/archive/v0.6.0-migration
  cp -r codemods/* docs/archive/v0.6.0-migration/
  echo "Migration scripts archived for future reference"
  ```
  > TEST: Archive Creation
  > Type: File Check
  > Assert: Archive directory contains scripts
  > Command: ls -la docs/archive/v0.6.0-migration/

- [ ] Clean up temporary files:
  ```bash
  # Remove codemods directory
  rm -rf codemods/

  # Remove old gem builds
  rm -f .ace/tools/coding-agent-tools-*.gem

  # Remove backup directories older than 7 days
  find backups/ -type d -mtime +7 -exec rm -rf {} \;
  ```
  > TEST: Cleanup Verification
  > Type: File System Check
  > Assert: Temporary files removed
  > Command: [ ! -d "codemods" ] && echo "Codemods removed"

- [ ] Update CI/CD configurations:
  - Update gem name in CI scripts
  - Update test commands
  - Update deployment scripts
  - Update GitHub Actions workflows

- [ ] Final verification sweep:
  ```bash
  echo "=== Final Verification ==="

  # No old module references
  ! grep -r "CodingAgentTools" . --exclude-dir=.git --exclude-dir=backups

  # No old paths
  ! grep -r "dev-tools\|dev-handbook\|dev-taskflow" . --exclude-dir=.git

  # New structure exists
  [ -d ".ace/tools/lib/ace_tools" ] && echo "✓ New structure verified"

  # Gem works
  ace-tools --version && echo "✓ Gem functional"
  ```
  > TEST: Final Sweep
  > Type: Comprehensive Check
  > Assert: No old references remain
  > Command: bash -c '! grep -r "CodingAgentTools" . --exclude-dir=.git'

- [ ] Update .gitignore:
  - Remove temporary migration entries
  - Add new patterns if needed
  - Clean up obsolete entries

- [ ] Document lessons learned:
  - Create post-mortem document
  - Note any issues encountered
  - Document solutions for future migrations

## Acceptance Criteria

- [ ] All temporary files removed
- [ ] Migration scripts archived
- [ ] CI/CD updated and working
- [ ] No old references in codebase
- [ ] Clean git status

## Out of Scope

- ❌ Performance optimization
- ❌ Feature additions
- ❌ Unrelated bug fixes