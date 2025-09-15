---
id: v.0.6.0+task.004
status: pending
priority: high
estimate: 4h
dependencies: [v.0.6.0+task.001, v.0.6.0+task.002, v.0.6.0+task.003]
---

# Execute Migration Codemods

## Objective

Execute all created codemods in the correct sequence to perform the complete migration from `dev-*` to `.ace/*` structure and from `CodingAgentTools` to `AceTools`.

## Scope of Work

- Create master execution script
- Execute path update codemods
- Execute Ruby module renaming
- Execute file/directory renaming
- Verify each phase before proceeding

### Deliverables

#### Create

- `codemods/run_all.sh` - Master execution script
- `codemods/backup.sh` - Backup creation script
- `codemods/migration.log` - Detailed migration log

#### Modify

- All ~1000+ files with path/module references

#### Delete

- Old directory structures after successful migration

## Implementation Plan

### Planning Steps

* [ ] Create full backup of current state
* [ ] Plan rollback strategy
* [ ] Set up migration logging

### Execution Steps

- [ ] Create backup script:
  ```bash
  #!/bin/bash
  # Create timestamped backup
  backup_dir="backups/migration-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$backup_dir"
  cp -r .ace "$backup_dir/"
  cp -r .coding-agent "$backup_dir/"
  cp -r docs "$backup_dir/"
  echo "Backup created in $backup_dir"
  ```
  > TEST: Backup Creation
  > Type: File System Check
  > Assert: Backup directory exists with all files
  > Command: ls -la backups/migration-*/

- [ ] Create master execution script:
  ```bash
  #!/bin/bash
  set -e  # Exit on error

  # Phase 1: Create backup
  ./codemods/backup.sh

  # Phase 2: Update paths
  echo "Phase 2: Updating paths..."
  ruby codemods/update_paths.rb --verbose

  # Phase 3: Rename files and directories
  echo "Phase 3: Renaming files..."
  ./codemods/rename_files.sh

  # Phase 4: Update Ruby modules
  echo "Phase 4: Updating Ruby modules..."
  ruby codemods/rename_ruby_module.rb --verbose

  # Phase 5: Verify
  echo "Phase 5: Verifying..."
  ./codemods/verify.sh
  ```

- [ ] Execute Phase 1 - Path updates:
  - Run update_paths.rb on all files
  - Log all changes
  - Verify with search commands
  > TEST: Path Update Verification
  > Type: Search Test
  > Assert: No old paths remain
  > Command: search "dev-tools/" --content --hidden

- [ ] Execute Phase 2 - File/directory renaming:
  - Run rename_files.sh
  - Preserve git history
  - Update git index
  > TEST: File Structure
  > Type: Directory Test
  > Assert: New structure exists
  > Command: ls -la .ace/tools/lib/ace_tools/

- [ ] Execute Phase 3 - Ruby module updates:
  - Run rename_ruby_module.rb
  - Update all Ruby files
  - Verify module loading
  > TEST: Module Loading
  > Type: Ruby Test
  > Assert: Module loads correctly
  > Command: ruby -e "require '.ace/tools/lib/ace_tools'"

## Acceptance Criteria

- [ ] All codemods execute without errors
- [ ] Backup created successfully
- [ ] Migration log contains all changes
- [ ] Each phase verified before proceeding
- [ ] Rollback possible if needed

## Out of Scope

- ❌ Test suite execution (task 005)
- ❌ Documentation updates (task 006)
- ❌ Release packaging (task 008)