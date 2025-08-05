---
id: v.0.6.0+task.020
status: draft
priority: high
estimate: TBD
dependencies: []
---

# Fix migration report file location and investigate path error

## Behavioral Specification

### User Experience
- **Input**: User runs a command or workflow that creates migration reports
- **Process**: System correctly determines the target directory based on release context (current vs releases)
- **Output**: Migration report is created in the correct location without manual intervention

### Expected Behavior
The system should automatically place migration reports in the correct directory structure based on the current release context. When working with a current release (v.0.6.0-unified-claude), reports should be created under `current/v.0.6.0-unified-claude/docs/` rather than `releases/v.0.6.0-unified-claude/docs/`. Users should not need to manually move files after creation.

### Interface Contract
```bash
# CLI Interface (hypothetical - need to identify actual command)
command-that-creates-migration-report
# Expected output location: dev-taskflow/current/v.0.6.0-unified-claude/docs/MIGRATION_REPORT.md

# Directory Structure Interface
dev-taskflow/
├── current/
│   └── v.0.6.0-unified-claude/
│       └── docs/
│           └── MIGRATION_REPORT.md  # Correct location
└── releases/
    └── v.0.6.0-unified-claude/
        └── docs/
            └── MIGRATION_REPORT.md  # Incorrect location
```

**Error Handling:**
- [File already exists]: System should warn and offer to overwrite or append
- [Permission denied]: Clear error message with suggested resolution
- [Invalid release version]: Inform user of valid release format

**Edge Cases:**
- [No current release]: Default to appropriate fallback location
- [Multiple current releases]: Use most recent or prompt for selection

### Success Criteria
- [ ] **Behavioral Outcome 1**: Migration reports are created in current/ directory when working on active releases
- [ ] **User Experience Goal 2**: No manual file movement required after report generation
- [ ] **System Performance 3**: File placement logic executes without noticeable delay

### Validation Questions
- [ ] **Requirement Clarity**: Which command or workflow created the migration report in the wrong location?
- [ ] **Edge Case Handling**: How should the system behave when transitioning a release from current to done?
- [ ] **User Experience**: Should existing reports be automatically migrated when detected in wrong location?
- [ ] **Success Definition**: Is there a broader pattern of path resolution issues that need addressing?

## Objective

Fix the incorrect file placement logic that causes migration reports to be created under releases/ instead of current/ directory, and investigate the root cause to prevent similar issues in other workflows.

## Scope of Work

- Move existing MIGRATION_REPORT.md to correct location
- Investigate which command/workflow created the file incorrectly
- Fix the path resolution logic in the responsible code
- Ensure consistent path handling across related commands

### Deliverables

#### Behavioral Specifications
- Clear understanding of correct vs incorrect file placement
- Path resolution logic specification
- Error handling requirements

#### Validation Artifacts
- Test cases for path resolution
- Verification of correct file placement
- Documentation of root cause

## Out of Scope

- ❌ **Implementation Details**: Specific code changes and file modifications
- ❌ **Technology Decisions**: Choice of path resolution libraries or methods
- ❌ **Performance Optimization**: Speed improvements beyond basic functionality
- ❌ **Future Enhancements**: Additional migration report features

## References

- Feedback item #7 from user input
- Current file location: dev-taskflow/releases/v.0.6.0-unified-claude/docs/MIGRATION_REPORT.md
- Expected location: dev-taskflow/current/v.0.6.0-unified-claude/docs/MIGRATION_REPORT.md