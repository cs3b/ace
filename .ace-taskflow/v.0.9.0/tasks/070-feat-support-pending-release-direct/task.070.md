---
id: v.0.9.0+task.070
status: pending
priority: medium
estimate: 4h
dependencies: []
---

# Add support for pending/ release directory

## Behavioral Specification

Add a new release state "pending" to represent releases that are approved and queued but not yet actively being worked on. This creates a clearer release lifecycle: `backlog → pending → active → done`.

### User Experience

**As a project manager**, I want to distinguish between:
- **Backlog releases**: Exploratory, not yet approved
- **Pending releases**: Approved and queued, waiting to start
- **Active releases**: Currently being worked on
- **Done releases**: Completed and archived

**When I run** `ace-taskflow releases`:
- I should see pending releases listed separately
- I should see the count of pending releases in statistics

**When I run** `ace-taskflow doctor`:
- Releases in `pending/` directory should be validated correctly
- Statistics should include pending release count

**When I use** release management commands:
- I can promote a backlog release to pending
- I can promote a pending release to active
- I can demote a pending release back to backlog

### Directory Structure

```
.ace-taskflow/
├── v.0.9.0/              # ACTIVE - being worked on
├── pending/              # PENDING - approved, queued (NEW)
│   └── v.0.11.0/
├── backlog/              # BACKLOG - unplanned, exploratory
│   └── some-idea/
└── done/                 # DONE - completed
    └── v.0.8.0/
```

## Acceptance Criteria

### Core Functionality
- [ ] Configuration supports `directories.pending: "pending"` setting
- [ ] `pending/` directory is recognized as valid release container
- [ ] Releases in `pending/` are detected with status "pending"
- [ ] Path builder correctly constructs pending release paths
- [ ] Context extraction identifies pending releases from paths

### Command Integration
- [ ] `ace-taskflow doctor` validates pending releases
- [ ] `ace-taskflow doctor` shows pending count in statistics
- [ ] `ace-taskflow releases` lists pending releases
- [ ] Tasks/ideas/retros in pending releases are accessible

### Validators
- [ ] Structure validator recognizes `pending/` as standard directory
- [ ] Release validator checks status matches location for pending
- [ ] Validator stats include pending counter

### State Transitions
- [ ] Can promote backlog release to pending
- [ ] Can promote pending release to active
- [ ] Can demote pending release back to backlog

## Implementation Plan

### Planning Steps

1. **Configuration Layer** (`lib/ace/taskflow/configuration.rb`)
   - Add `pending_dir` getter method
   - Returns `config.dig("directories", "pending") || "pending"`

2. **Path Builder** (`lib/ace/taskflow/atoms/path_builder.rb`)
   - Update `build_release_path` to handle "pending" status
   - Update `extract_context` to detect `/pending/` in paths

3. **Release Resolver** (`lib/ace/taskflow/molecules/release_resolver.rb`)
   - Update `find_all` to scan `pending/` directory
   - Update `resolve_context` to handle "pending" context string

4. **Structure Validator** (`lib/ace/taskflow/molecules/structure_validator.rb`)
   - Add "pending" to standard directories check
   - Add pending release scanning in `validate_releases`
   - Add `:pending` key to stats hash

5. **Release Validator** (`lib/ace/taskflow/molecules/release_validator.rb`)
   - Update `validate_status_location` with pending case
   - Update `determine_actual_location` to detect pending
   - Add pending counter to stats

6. **Doctor Reporter** (`lib/ace/taskflow/molecules/doctor_reporter.rb`)
   - Update `format_system_stats` to show pending count in releases line

7. **Release Manager** (`lib/ace/taskflow/organisms/release_manager.rb`)
   - Verify promote/demote operations support pending transitions

8. **Config File** (`.ace/taskflow/config.yml`)
   - Add `directories.pending: "pending"` configuration

### Execution Steps

1. Add configuration getter and update config.yml
2. Update path builder for pending paths
3. Update release resolver to find pending releases
4. Update structure validator for pending support
5. Update release validator for pending validation
6. Update doctor reporter to display pending stats
7. Test with manual pending directory creation
8. Verify all commands work with pending releases

## Technical Approach

- **Consistent pattern**: Follow same approach as backlog/done directories
- **Configuration-driven**: Use configured directory name, default to "pending"
- **State validation**: Ensure releases in pending/ have correct status
- **Backward compatible**: No breaking changes, purely additive

## Files to Modify

1. `lib/ace/taskflow/configuration.rb` - Add pending_dir getter
2. `lib/ace/taskflow/atoms/path_builder.rb` - Handle pending paths
3. `lib/ace/taskflow/molecules/release_resolver.rb` - Find pending releases
4. `lib/ace/taskflow/molecules/structure_validator.rb` - Validate pending
5. `lib/ace/taskflow/molecules/release_validator.rb` - Validate pending status
6. `lib/ace/taskflow/molecules/doctor_reporter.rb` - Show pending stats
7. `.ace/taskflow/config.yml` - Add pending directory config

## Testing Plan

1. **Manual Testing**:
   - Create `pending/` directory
   - Move a release to `pending/v.0.11.0/`
   - Run `ace-taskflow doctor` → should recognize it
   - Run `ace-taskflow releases` → should list it

2. **Validation Testing**:
   - Verify pending releases appear in statistics
   - Verify tasks in pending releases are listable
   - Verify ideas in pending releases are listable

## Notes

- Release manager promote/demote operations should already support this (verify)
- Task/idea/retro loaders should work automatically (they follow patterns)
- This is purely additive - no breaking changes to existing functionality
